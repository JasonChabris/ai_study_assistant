/// 知识点节点（思维导图结构）
class KnowledgeNode {
  final String title;
  final String detail;
  final String level; // 重点/难点/了解
  final List<KnowledgeNode> children;

  KnowledgeNode({
    required this.title,
    required this.detail,
    required this.level,
    this.children = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
        'level': level,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory KnowledgeNode.fromJson(Map<String, dynamic> json) => KnowledgeNode(
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        level: json['level']?.toString() ?? '了解',
        children: (json['children'] as List?)
                ?.whereType<Map>()
                .map((c) => KnowledgeNode.fromJson(Map<String, dynamic>.from(c)))
                .toList() ??
            [],
      );
}

/// 一次知识点梳理结果
class KnowledgeResult {
  final String id;
  final String subject;
  final String grade;
  final String keyword;
  final String overview;
  final List<KnowledgeNode> nodes;
  final List<String> mistakes; // 易错点
  final DateTime createdAt;

  KnowledgeResult({
    String? id,
    required this.subject,
    required this.grade,
    required this.keyword,
    required this.overview,
    required this.nodes,
    required this.mistakes,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'grade': grade,
        'keyword': keyword,
        'overview': overview,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'mistakes': mistakes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KnowledgeResult.fromJson(Map<String, dynamic> json) => KnowledgeResult(
        id: json['id']?.toString(),
        subject: json['subject']?.toString() ?? '',
        grade: json['grade']?.toString() ?? '',
        keyword: json['keyword']?.toString() ?? '',
        overview: json['overview']?.toString() ?? '',
        nodes: (json['nodes'] as List?)
                ?.whereType<Map>()
                .map((n) => KnowledgeNode.fromJson(Map<String, dynamic>.from(n)))
                .toList() ??
            [],
        mistakes: (json['mistakes'] as List?)?.map((m) => m.toString()).toList() ?? [],
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
