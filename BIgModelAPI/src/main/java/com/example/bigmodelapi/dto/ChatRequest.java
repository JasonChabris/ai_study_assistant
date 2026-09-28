package com.example.bigmodelapi.dto;

import java.util.List;

public record ChatRequest(String message, String image, String mime, List<ChatTurn> history) {

    public record ChatTurn(String role, String content, String image, String mime) {
    }
}
