package com.example.bigmodelapi;

import com.example.bigmodelapi.controller.ChatController;
import com.example.bigmodelapi.dto.ChatRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertFalse;

@SpringBootTest
class BIgModelApiApplicationTests {

    @Autowired
    private ChatController chatController;

    @Test
    void chatStreamsReply() {
        long started = System.currentTimeMillis();
        StringBuilder answer = new StringBuilder();
        chatController.chat(new ChatRequest("你是谁", null, null, null))
                .doOnNext(piece -> {
                    System.out.print(piece);
                    System.out.flush();
                    answer.append(piece);
                })
                .blockLast(Duration.ofMinutes(3));
        System.out.println();
        long seconds = (System.currentTimeMillis() - started) / 1000;
        System.out.println("回答结束，用时 " + seconds + " 秒");
        assertFalse(answer.toString().isBlank(), "流式回答是空的");
    }

}
