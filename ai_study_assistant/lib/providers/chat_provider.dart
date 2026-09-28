import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// AI 对话状态管理
class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<ChatSession> _sessions = [];
  ChatSession? _current;
  bool _busy = false;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  ChatSession? get current => _current;
  bool get busy => _busy;

  /// 启动时加载历史记录
  Future<void> load() async {
    final list = await StorageService.getChatSessions();
    if (list != null) {
      _sessions =
          list.map((e) => ChatSession.fromJson(e)).toList().reversed.toList();
    }
    notifyListeners();
  }

  /// 新建对话
  void newSession() {
    _current = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '新对话',
      updateTime: DateTime.now(),
      messages: [],
    );
    notifyListeners();
  }

  /// 选择历史会话
  void selectSession(ChatSession s) {
    _current = s;
    notifyListeners();
  }

  /// 发送消息。回答通过 SSE 逐段写入当前气泡。
  Future<void> sendMessage(String text, {String? imageUrl}) async {
    if (_busy) return;
    if (text.trim().isEmpty && imageUrl == null) return;
    _current ??= ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text.isEmpty ? '图片搜题' : text,
      updateTime: DateTime.now(),
      messages: [],
    );

    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      isUser: true,
      time: DateTime.now(),
      imageUrl: imageUrl,
    );
    _current!.messages.add(userMsg);

    final prior = _current!.messages
        .where((m) => !m.isTyping)
        .where((m) => m.content.trim().isNotEmpty || (m.imageUrl?.isNotEmpty ?? false))
        .toList();
    if (prior.isNotEmpty) prior.removeLast();
    final history = <Map<String, dynamic>>[];
    final start = prior.length > 10 ? prior.length - 10 : 0;
    for (final turn in prior.sublist(start)) {
      final item = <String, dynamic>{
        'role': turn.isUser ? 'user' : 'assistant',
        'content': turn.content,
      };
      if (turn.isUser) await _attachImage(item, turn.imageUrl);
      history.add(item);
    }
    final currentImage = await _readImage(imageUrl);
    if (imageUrl != null && currentImage == null) {
      _current!.messages.add(ChatMessage(
        id: 'e_${DateTime.now().millisecondsSinceEpoch}',
        content: '图片读取失败，请重新选择一张更小的图片。',
        isUser: false,
        time: DateTime.now(),
      ));
      await _persist();
      notifyListeners();
      return;
    }

    // 打字中占位
    final typingId = 't_${DateTime.now().millisecondsSinceEpoch}';
    final typing = ChatMessage(
      id: typingId,
      content: '',
      isUser: false,
      time: DateTime.now(),
      isTyping: true,
    );
    _current!.messages.add(typing);
    _busy = true;
    notifyListeners();

    final buffer = StringBuffer();
    try {
      await for (final piece in _api.askQuestion(
        text,
        history: history,
        imageBase64: currentImage?.$1,
        mime: currentImage?.$2 ?? 'image/jpeg',
      )) {
        buffer.write(piece);
        _replaceMessage(typingId, buffer.toString(), typing: true);
      }
    } catch (_) {
      if (buffer.isEmpty) {
        buffer.write('回答中断了，请再试一次。');
      }
    }

    final reply = buffer.toString().trim();
    _replaceMessage(
      typingId,
      reply.isEmpty ? '模型没有返回内容，请再试一次。' : reply,
      typing: false,
    );
    _busy = false;

    // 标题取首句
    if (_current!.title == '新对话' || _current!.title == '图片搜题') {
      _current = ChatSession(
        id: _current!.id,
        title: text.isEmpty ? '图片搜题' : (text.length > 12 ? text.substring(0, 12) : text),
        updateTime: DateTime.now(),
        messages: _current!.messages,
      );
    }
    await _persist();
    notifyListeners();
  }

  /// 删除会话
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    if (_current?.id == id) _current = null;
    await _persist();
    notifyListeners();
  }

  void _replaceMessage(String id, String content, {required bool typing}) {
    final messages = _current?.messages;
    if (messages == null) return;
    final index = messages.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final old = messages[index];
    messages[index] = ChatMessage(
      id: old.id,
      content: content,
      isUser: false,
      time: old.time,
      isTyping: typing,
    );
    notifyListeners();
  }

  Future<(String, String)?> _readImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length <= 0 || length > 4 * 1024 * 1024) return null;
    return (base64Encode(await file.readAsBytes()), _mimeFor(path));
  }

  Future<void> _attachImage(Map<String, dynamic> item, String? path) async {
    final image = await _readImage(path);
    if (image == null) return;
    item['image'] = image.$1;
    item['mime'] = image.$2;
  }

  String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _persist() async {
    // 合并：把 current 放回列表
    final map = {for (final s in _sessions) s.id: s};
    if (_current != null) map[_current!.id] = _current!;
    _sessions = map.values.toList();
    await StorageService.saveChatSessions(
        _sessions.map((s) => s.toJson()).toList());
  }
}
