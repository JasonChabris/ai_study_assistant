/// 模拟试题题目
class ExamQuestion {
  final String id;
  final String type; // 选择/填空/简答/计算
  final String subject;
  final String stem; // 题干
  final List<String> options; // 选项（选择题用）
  final String answer; // 标准答案
  final String analysis; // 解析
  final String difficulty; // 简单/中等/困难
  final String knowledge; // 关联知识点

  String userAnswer; // 用户作答

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: json['type']?.toString() ?? '简答',
        subject: json['subject']?.toString() ?? '',
        stem: json['stem']?.toString() ?? '',
        options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        answer: json['answer']?.toString() ?? '',
        analysis: json['analysis']?.toString() ?? '',
        difficulty: json['difficulty']?.toString() ?? '中等',
        knowledge: json['knowledge']?.toString() ?? '',
      );

  ExamQuestion({
    required this.id,
    required this.type,
    required this.subject,
    required this.stem,
    required this.options,
    required this.answer,
    required this.analysis,
    required this.difficulty,
    required this.knowledge,
    this.userAnswer = '',
  });
}

/// 一次模拟考试配置
class ExamConfig {
  final String subject;
  final String grade;
  final String knowledgeRange;
  final int count;
  final List<String> types; // 题型
  final String difficulty;

  ExamConfig({
    required this.subject,
    required this.grade,
    required this.knowledgeRange,
    required this.count,
    required this.types,
    required this.difficulty,
  });
}
