/// 错题模型
class WrongQuestion {
  final String id;
  final String subject;
  final String question;
  final String? imageUrl;
  final String userAnswer;
  final String correctAnswer;
  final String analysis;
  final String errorType; // 概念错误/计算失误/审题不清/知识点盲区
  final DateTime createdAt;
  bool mastered; // 是否已掌握

  WrongQuestion({
    required this.id,
    required this.subject,
    required this.question,
    this.imageUrl,
    required this.userAnswer,
    required this.correctAnswer,
    required this.analysis,
    required this.errorType,
    required this.createdAt,
    this.mastered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'question': question,
        'imageUrl': imageUrl,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'analysis': analysis,
        'errorType': errorType,
        'createdAt': createdAt.toIso8601String(),
        'mastered': mastered,
      };

  factory WrongQuestion.fromJson(Map<String, dynamic> json) => WrongQuestion(
        id: json['id'],
        subject: json['subject'] ?? '数学',
        question: json['question'] ?? '',
        imageUrl: json['imageUrl'],
        userAnswer: json['userAnswer'] ?? '',
        correctAnswer: json['correctAnswer'] ?? '',
        analysis: json['analysis'] ?? '',
        errorType: json['errorType'] ?? '知识点盲区',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        mastered: json['mastered'] ?? false,
      );
}
