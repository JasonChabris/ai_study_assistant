/// 单词
class Word {
  final String word;
  final String phonetic;
  final String meaning;
  final String example;
  int reviewCount; // 艾宾浩斯复习次数

  Word({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.example,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'meaning': meaning,
        'example': example,
        'reviewCount': reviewCount,
      };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        word: json['word'] ?? '',
        phonetic: json['phonetic'] ?? '',
        meaning: json['meaning'] ?? '',
        example: json['example'] ?? '',
        reviewCount: json['reviewCount'] ?? 0,
      );
}

/// 学习笔记
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
