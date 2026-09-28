/// AI 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime time;
  final String? imageUrl; // 拍照/图片搜题
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.time,
    this.imageUrl,
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'time': time.toIso8601String(),
        'imageUrl': imageUrl,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        content: json['content'] ?? '',
        isUser: json['isUser'] ?? false,
        time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
        imageUrl: json['imageUrl'],
      );
}

/// 对话会话
class ChatSession {
  final String id;
  final String title;
  final DateTime updateTime;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updateTime,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updateTime': updateTime.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'] ?? '新对话',
        updateTime: DateTime.tryParse(json['updateTime'] ?? '') ?? DateTime.now(),
        messages: (json['messages'] as List?)
                ?.map((m) => ChatMessage.fromJson(m))
                .toList() ??
            [],
      );
}
