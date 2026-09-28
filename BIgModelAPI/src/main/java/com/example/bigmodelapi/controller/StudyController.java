package com.example.bigmodelapi.controller;

import com.example.bigmodelapi.dto.StudyRequest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api")
public class StudyController {

    private static final Logger log = LoggerFactory.getLogger(StudyController.class);

    private static final String SYSTEM_PROMPT = """
            你是面向中学生的学习助手。只用简体中文。
            只输出一个 JSON 对象，不要 Markdown，不要代码块，不要额外说明。
            不要编造课本页码或并不存在的原文。
            """;

    private static final Set<String> LEVELS = Set.of("重点", "难点", "了解");
    private static final Set<String> QUESTION_TYPES = Set.of("选择", "填空", "简答", "计算");
    private static final Set<String> TASK_TYPES = Set.of("刷题", "知识点复习", "背诵");
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final Duration MODEL_WAIT = Duration.ofSeconds(45);

    private final ChatClient chatClient;

    public StudyController(ChatClient.Builder chatClientBuilder) {
        this.chatClient = chatClientBuilder.build();
    }

    @PostMapping("/knowledge")
    public ResponseEntity<Map<String, Object>> knowledge(@RequestBody StudyRequest.Knowledge request) {
        String subject = clean(request.subject(), 20);
        String grade = clean(request.grade(), 20);
        if (subject.isEmpty() || grade.isEmpty()) {
            return bad("请选择学科和年级。");
        }
        String keyword = clean(request.keyword(), 40);
        if (keyword.isEmpty()) {
            keyword = "核心知识点";
        }
        String prompt = """
                请为%s%s梳理知识点「%s」。
                只输出这个结构的 JSON：
                {"overview":"两到三句总述","nodes":[{"title":"","detail":"具体说明","level":"重点","children":[{"title":"","detail":"","level":"难点","children":[]}]}],"mistakes":["易错点"]}
                要求：nodes 正好 3 个；每个节点的 children 正好 2 个，且不要再往下嵌套；
                level 只能是重点、难点、了解；mistakes 正好 4 条。
                写清定义、公式或判断方法，不要空话。
                """.formatted(grade, subject, keyword);
        try {
            JsonNode root = askJson(prompt);
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("subject", subject);
            body.put("grade", grade);
            body.put("keyword", keyword);
            body.put("overview", text(root.get("overview"), 400));
            body.put("nodes", nodes(root.get("nodes"), 0));
            body.put("mistakes", strings(root.get("mistakes"), 6));
            if (((List<?>) body.get("nodes")).isEmpty()) {
                return fail("梳理结果不完整，请再试一次。");
            }
            return ResponseEntity.ok(body);
        } catch (IllegalArgumentException ex) {
            return fail(ex.getMessage());
        } catch (RuntimeException ex) {
            return fail("模型暂时没有响应，请再试一次。");
        }
    }

    @PostMapping("/exam")
    public ResponseEntity<Map<String, Object>> exam(@RequestBody StudyRequest.Exam request) {
        String subject = clean(request.subject(), 20);
        String grade = clean(request.grade(), 20);
        if (subject.isEmpty() || grade.isEmpty()) {
            return bad("请选择学科和年级。");
        }
        int count = request.count() == null ? 5 : request.count();
        if (count < 1 || count > 15) {
            return bad("题目数量需要在 1 到 15 之间。");
        }
        List<String> types = new ArrayList<>();
        if (request.types() != null) {
            for (String type : request.types()) {
                String value = clean(type, 8);
                if (QUESTION_TYPES.contains(value) && !types.contains(value)) {
                    types.add(value);
                }
            }
        }
        if (types.isEmpty()) {
            return bad("请至少选择一种题型。");
        }
        String difficulty = clean(request.difficulty(), 8);
        if (!Set.of("简单", "中等", "困难").contains(difficulty)) {
            difficulty = "中等";
        }
        String range = clean(request.knowledgeRange(), 40);
        if (range.isEmpty()) {
            range = "核心知识点";
        }
        List<String> plan = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            plan.add(types.get(i % types.size()));
        }
        String prompt = """
                请出一套%s%s试卷。知识点范围：%s。难度：%s。
                一共 %d 题，题型顺序必须是：%s。
                只输出这个结构的 JSON：
                {"questions":[{"type":"选择","stem":"题干","options":["A. ","B. ","C. ","D. "],"answer":"B","analysis":"解析"}]}
                要求：选择题正好 4 个选项，answer 只能是 A、B、C、D；
                填空、简答、计算的 options 用空数组，answer 写可对照的文字答案；
                题目条件要完整，能直接作答；题干不超过 120 字，解析不超过 80 字。
                """.formatted(grade, subject, range, difficulty, count, String.join("、", plan));
        try {
            JsonNode root = askJson(prompt);
            List<Map<String, Object>> questions = questions(root.get("questions"), plan, subject, difficulty, range);
            if (questions.isEmpty()) {
                return fail("试题结果不完整，请再试一次。");
            }
            return ResponseEntity.ok(Map.of("questions", questions));
        } catch (IllegalArgumentException ex) {
            return fail(ex.getMessage());
        } catch (RuntimeException ex) {
            return fail("模型暂时没有响应，请再试一次。");
        }
    }

    @PostMapping("/plan")
    public ResponseEntity<Map<String, Object>> plan(@RequestBody StudyRequest.Plan request) {
        String grade = clean(request.grade(), 10);
        if (grade.isEmpty()) {
            grade = "高中";
        }
        List<String> hints = new ArrayList<>();
        if (request.hints() != null) {
            for (String hint : request.hints()) {
                String value = clean(hint, 40);
                if (!value.isEmpty() && hints.size() < 6) {
                    hints.add(value);
                }
            }
        }
        String context = hints.isEmpty()
                ? "学生还没有错题和收藏记录。"
                : "学生近期情况：" + String.join("；", hints);
        String prompt = """
                请为%s学生安排今天的学习计划。%s
                只输出 JSON：
                {"weakPoints":["薄弱点"],"tasks":[{"title":"具体任务","subject":"数学","type":"刷题","estimatedMinutes":20}]}
                要求：weakPoints 正好 3 个；tasks 正好 5 个；
                type 只能是刷题、知识点复习、背诵；
                estimatedMinutes 是 10 到 40 的整数；
                任务要具体到知识点或题量，至少覆盖 2 个学科；
                如果有近期情况，优先安排对应内容。
                """.formatted(grade, context);
        try {
            JsonNode root = askJson(prompt);
            List<String> weakPoints = strings(root.get("weakPoints"), 4);
            List<Map<String, Object>> tasks = planTasks(root.get("tasks"));
            if (weakPoints.isEmpty() || tasks.isEmpty()) {
                return fail("学习计划不完整，请再试一次。");
            }
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("weakPoints", weakPoints);
            body.put("tasks", tasks);
            return ResponseEntity.ok(body);
        } catch (IllegalArgumentException ex) {
            return fail(ex.getMessage());
        } catch (RuntimeException ex) {
            return fail("模型暂时没有响应，请再试一次。");
        }
    }

    private JsonNode askJson(String prompt) {
        String first = complete(prompt);
        try {
            return MAPPER.readTree(extractJson(first));
        } catch (IllegalArgumentException ex) {
            throw ex;
        } catch (Exception ignored) {
            String second = complete(prompt + "\n上一次不是合法 JSON。这次只输出 JSON 对象。");
            try {
                return MAPPER.readTree(extractJson(second));
            } catch (IllegalArgumentException ex) {
                throw ex;
            } catch (Exception ex) {
                throw new IllegalArgumentException("结果无法解析，请再试一次。");
            }
        }
    }

    private String complete(String prompt) {
        try {
            String content = chatClient.prompt()
                    .system(SYSTEM_PROMPT)
                    .user(prompt)
                    .options(OpenAiChatOptions.builder()
                            .temperature(0.4)
                            .maxTokens(1200)
                            .timeout(MODEL_WAIT)
                            .reasoningEffort("low"))
                    .call()
                    .content();
            if (content == null || content.isBlank()) {
                throw new IllegalArgumentException("模型没有返回内容，请再试一次。");
            }
            return content;
        } catch (IllegalArgumentException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            log.warn("model call failed", ex);
            String detail = ex.getMessage() == null ? "" : ex.getMessage().toLowerCase();
            if (detail.contains("timeout") || detail.contains("timed out") || detail.contains("cancel")) {
                throw new IllegalArgumentException("生成超时了，请再试一次。");
            }
            throw new IllegalArgumentException("生成失败了，请再试一次。");
        }
    }

    private static String extractJson(String raw) {
        String text = raw.trim();
        if (text.startsWith("```")) {
            int start = text.indexOf('\n');
            int end = text.lastIndexOf("```");
            if (start >= 0 && end > start) {
                text = text.substring(start + 1, end).trim();
            }
        }
        int left = text.indexOf('{');
        int right = text.lastIndexOf('}');
        if (left < 0 || right <= left) {
            throw new IllegalArgumentException("结果无法解析，请再试一次。");
        }
        return text.substring(left, right + 1);
    }

    private static List<Map<String, Object>> nodes(JsonNode array, int depth) {
        List<Map<String, Object>> list = new ArrayList<>();
        if (array == null || !array.isArray() || depth > 1) {
            return list;
        }
        for (JsonNode item : array) {
            if (list.size() >= 6) {
                break;
            }
            String title = text(item.get("title"), 40);
            if (title.isEmpty()) {
                continue;
            }
            Map<String, Object> node = new LinkedHashMap<>();
            node.put("title", title);
            node.put("detail", text(item.get("detail"), 160));
            node.put("level", level(item.get("level")));
            node.put("children", nodes(item.get("children"), depth + 1));
            list.add(node);
        }
        return list;
    }

    private static List<Map<String, Object>> planTasks(JsonNode array) {
        List<Map<String, Object>> list = new ArrayList<>();
        if (array == null || !array.isArray()) {
            return list;
        }
        for (JsonNode item : array) {
            if (list.size() >= 5) {
                break;
            }
            String title = text(item.get("title"), 40);
            if (title.isEmpty()) {
                continue;
            }
            String type = text(item.get("type"), 8);
            if (!TASK_TYPES.contains(type)) {
                type = "刷题";
            }
            int minutes = item.path("estimatedMinutes").asInt(20);
            if (minutes < 10) {
                minutes = 10;
            }
            if (minutes > 40) {
                minutes = 40;
            }
            String subject = text(item.get("subject"), 8);
            if (subject.isEmpty()) {
                subject = "综合";
            }
            Map<String, Object> task = new LinkedHashMap<>();
            task.put("id", "t" + (list.size() + 1));
            task.put("title", title);
            task.put("subject", subject);
            task.put("type", type);
            task.put("estimatedMinutes", minutes);
            task.put("completed", false);
            list.add(task);
        }
        return list;
    }

    private static List<Map<String, Object>> questions(
            JsonNode array,
            List<String> plan,
            String subject,
            String difficulty,
            String knowledge) {
        List<Map<String, Object>> list = new ArrayList<>();
        if (array == null || !array.isArray()) {
            return list;
        }
        int index = 0;
        for (JsonNode item : array) {
            if (list.size() >= plan.size()) {
                break;
            }
            String type = text(item.get("type"), 8);
            if (!QUESTION_TYPES.contains(type)) {
                type = plan.get(Math.min(index, plan.size() - 1));
            }
            String stem = text(item.get("stem"), 240);
            if (stem.isEmpty()) {
                index++;
                continue;
            }
            List<String> options = "选择".equals(type) ? choiceOptions(item.get("options")) : List.of();
            String answer = text(item.get("answer"), 200);
            if ("选择".equals(type)) {
                if (options.size() < 2) {
                    index++;
                    continue;
                }
                answer = choiceAnswer(answer, options);
            } else if (answer.isEmpty()) {
                answer = "见解析";
            }
            Map<String, Object> question = new LinkedHashMap<>();
            question.put("id", "q_" + (list.size() + 1));
            question.put("type", type);
            question.put("subject", subject);
            question.put("stem", stem);
            question.put("options", options);
            question.put("answer", answer);
            question.put("analysis", text(item.get("analysis"), 240));
            question.put("difficulty", difficulty);
            question.put("knowledge", knowledge);
            list.add(question);
            index++;
        }
        return list;
    }

    private static List<String> choiceOptions(JsonNode array) {
        List<String> raw = strings(array, 4);
        List<String> options = new ArrayList<>();
        for (int i = 0; i < raw.size() && options.size() < 4; i++) {
            String text = raw.get(i);
            char letter = (char) ('A' + options.size());
            if (text.length() >= 2 && text.charAt(0) == letter && (text.charAt(1) == '.' || text.charAt(1) == '、' || text.charAt(1) == ' ')) {
                options.add(letter + ". " + text.substring(2).trim());
            } else if (text.length() >= 1 && text.charAt(0) == letter) {
                options.add(letter + ". " + text.substring(1).replaceFirst("^[.、\\s]+", ""));
            } else {
                options.add(letter + ". " + text);
            }
        }
        return options;
    }

    private static String choiceAnswer(String answer, List<String> options) {
        String raw = answer.trim().toUpperCase();
        if (!raw.isEmpty()) {
            char letter = raw.charAt(0);
            if (letter >= 'A' && letter < 'A' + options.size()) {
                return String.valueOf(letter);
            }
        }
        for (String option : options) {
            String body = option.length() > 3 ? option.substring(3) : option;
            if (!answer.isBlank() && (option.contains(answer.trim()) || answer.trim().contains(body))) {
                return String.valueOf(option.charAt(0));
            }
        }
        return "A";
    }

    private static List<String> strings(JsonNode array, int limit) {
        List<String> list = new ArrayList<>();
        if (array == null || !array.isArray()) {
            return list;
        }
        for (JsonNode item : array) {
            if (list.size() >= limit) {
                break;
            }
            String value = text(item, 200);
            if (!value.isEmpty()) {
                list.add(value);
            }
        }
        return list;
    }

    private static String level(JsonNode node) {
        String value = text(node, 8);
        return LEVELS.contains(value) ? value : "了解";
    }

    private static String text(JsonNode node, int max) {
        if (node == null || node.isNull()) {
            return "";
        }
        String value = node.asText("").trim().replaceAll("\\s+", " ");
        if (value.length() > max) {
            return value.substring(0, max);
        }
        return value;
    }

    private static String clean(String value, int max) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim().replaceAll("\\s+", " ");
        if (trimmed.length() > max) {
            return trimmed.substring(0, max);
        }
        return trimmed;
    }

    private static ResponseEntity<Map<String, Object>> bad(String message) {
        return ResponseEntity.badRequest().body(Map.of("message", message));
    }

    private static ResponseEntity<Map<String, Object>> fail(String message) {
        return ResponseEntity.unprocessableEntity().body(Map.of("message", message));
    }
}
