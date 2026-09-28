package com.example.bigmodelapi.dto;

import java.util.List;

public final class StudyRequest {

    private StudyRequest() {
    }

    public record Knowledge(String subject, String grade, String keyword) {
    }

    public record Plan(String grade, List<String> hints) {
    }

    public record Exam(
            String subject,
            String grade,
            String knowledgeRange,
            Integer count,
            List<String> types,
            String difficulty) {
    }
}
