package com.example.bigmodelapi.controller;

import com.example.bigmodelapi.dto.ChatRequest;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.content.Media;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.util.MimeType;
import org.springframework.util.MimeTypeUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    // private static final String SYSTEM_PROMPT = """
    //         你是面向中学生的 AI 学习助手。用简体中文回答。
    //         讲题时分步骤说明思路、关键公式和易错点，语气清楚、直接。
    //         如果用户发来题目图片，先读出题目，再分步骤讲解。
    //         不要编造课本页码或并不存在的原文。
    //         """;


    private static final String SYSTEM_PROMPT = """
            你是面向在韩国面向宝妈的Ai助手 你的任务是回答宝妈的问题 以及根据他们的B超图片告诉他们宝宝的健康情况以及性别
            """;

    private static final int MAX_HISTORY = 10;
    private static final int MAX_IMAGE_BYTES = 4 * 1024 * 1024;
    private static final String IMAGE_PROMPT = "请根据这张图片里的题目，分步骤讲解。";
    private static final Set<String> IMAGE_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp", "image/gif");

    private final ChatClient chatClient;

    public ChatController(ChatClient.Builder chatClientBuilder) {
        this.chatClient = chatClientBuilder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
    }


    // 一次性 JSON：
    @PostMapping(value = "/sync", produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, String> chatSync(@RequestBody ChatRequest request) {
        try {
            if (isEmpty(request)) {
                return Map.of("reply", "请输入你的问题，或上传一张题目图片。");
            }
            String reply = prompt(request).call().content();
            return Map.of("reply", reply == null || reply.isBlank() ? "模型没有返回内容，请再试一次。" : reply);
        } catch (IllegalArgumentException ex) {
            return Map.of("reply", ex.getMessage());
        }
    }

    // 流式 SSE，可附带 image（base64）和 mime：
    @PostMapping(produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> chat(@RequestBody ChatRequest request) {
        try {
            if (isEmpty(request)) {
                return Flux.just("请输入你的问题，或上传一张题目图片。");
            }
            return prompt(request).stream().content();
        } catch (IllegalArgumentException ex) {
            return Flux.just(ex.getMessage());
        }
    }

    @GetMapping
    public String usage() {
        return """
                <h2>智谱 GLM 学习助手接口</h2>
                <p>一次性 JSON：</p>
                <pre>curl -X POST http://localhost:8080/api/chat/sync \\
                  -H 'Content-Type: application/json' \\
                  -d '{"message":"一元二次方程怎么解？"}'</pre>
                <p>流式 SSE，可附带 image（base64）和 mime：</p>
                <pre>curl -N -X POST http://localhost:8080/api/chat \\
                  -H 'Content-Type: application/json' \\
                  -d '{"message":"请讲解这道题","mime":"image/jpeg","image":"..."}'</pre>
                """;
    }

    private boolean isEmpty(ChatRequest request) {
        boolean noText = request.message() == null || request.message().isBlank();
        boolean noImage = request.image() == null || request.image().isBlank();
        return noText && noImage;
    }

    private ChatClient.ChatClientRequestSpec prompt(ChatRequest request) {
        List<Message> messages = new ArrayList<>();
        if (request.history() != null) {
            int start = Math.max(0, request.history().size() - MAX_HISTORY);
            for (int i = start; i < request.history().size(); i++) {
                ChatRequest.ChatTurn turn = request.history().get(i);
                if (turn == null) {
                    continue;
                }
                if ("assistant".equalsIgnoreCase(turn.role())) {
                    if (turn.content() == null || turn.content().isBlank()) {
                        continue;
                    }
                    messages.add(new AssistantMessage(turn.content()));
                    continue;
                }
                Message user = userMessage(turn.content(), turn.image(), turn.mime(), false);
                if (user != null) {
                    messages.add(user);
                }
            }
        }
        Message current = userMessage(request.message(), request.image(), request.mime(), true);
        if (current == null) {
            throw new IllegalArgumentException("请输入你的问题，或上传一张题目图片。");
        }
        ChatClient.ChatClientRequestSpec spec = chatClient.prompt();
        if (!messages.isEmpty()) {
            spec = spec.messages(messages);
        }
        return spec.messages(current);
    }

    private Message userMessage(String content, String image, String mime, boolean required) {
        byte[] bytes = null;
        if (image != null && !image.isBlank()) {
            try {
                bytes = decodeImage(image);
            } catch (IllegalArgumentException ex) {
                if (required) {
                    throw ex;
                }
            }
        }
        String text = content == null ? "" : content.trim();
        if (bytes == null) {
            return text.isEmpty() ? null : new UserMessage(text);
        }
        if (text.isEmpty()) {
            text = IMAGE_PROMPT;
        }
        Media media = new Media(imageMime(mime), new ByteArrayResource(bytes));
        return UserMessage.builder().text(text).media(media).build();
    }

    private static byte[] decodeImage(String raw) {
        String data = raw.trim();
        int comma = data.indexOf(',');
        if (data.regionMatches(true, 0, "data:", 0, 5) && comma > 0) {
            data = data.substring(comma + 1);
        }
        data = data.replaceAll("\\s", "");
        final byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(data);
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("图片无法读取，请换一张再试。");
        }
        if (bytes.length == 0) {
            throw new IllegalArgumentException("图片是空的，请换一张再试。");
        }
        if (bytes.length > MAX_IMAGE_BYTES) {
            throw new IllegalArgumentException("图片太大，请换一张更小的再试。");
        }
        return bytes;
    }

    private static MimeType imageMime(String mime) {
        String value = mime == null ? "" : mime.trim().toLowerCase();
        if (value.isEmpty() || "image/jpg".equals(value) || "image/pjpeg".equals(value)) {
            value = "image/jpeg";
        }
        if (!IMAGE_TYPES.contains(value)) {
            throw new IllegalArgumentException("只支持 jpg、png、webp、gif 图片。");
        }
        return MimeTypeUtils.parseMimeType(value);
    }


}
