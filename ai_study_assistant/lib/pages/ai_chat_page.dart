import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/wrong_question_provider.dart';
import '../models/chat_message.dart';
import '../models/wrong_question.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  String? _pendingImage;

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatProvider>();
    if (chat.current == null) chat.newSession();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (context.read<ChatProvider>().busy) return;
    final text = _inputCtrl.text.trim();
    final image = _pendingImage;
    if (text.isEmpty && image == null) return;
    context.read<ChatProvider>().sendMessage(text, imageUrl: image);
    _inputCtrl.clear();
    setState(() => _pendingImage = null);
    _scrollToBottom(force: true);
  }

  Future<void> _chooseImage() async {
    if (context.read<ChatProvider>().busy) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;
      final saved = await _storeImage(picked);
      if (!mounted) return;
      if (saved == null) {
        _toast('图片太大或无法读取，请换一张。');
        return;
      }
      setState(() => _pendingImage = saved);
    } catch (_) {
      if (!mounted) return;
      _toast(source == ImageSource.camera ? '无法打开相机，请改用相册。' : '无法打开相册。');
    }
  }

  Future<String?> _storeImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/chat_images');
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = File('${folder.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final position = _scrollCtrl.position;
      final distance = position.maxScrollExtent - position.pixels;
      if (!force && distance > 120) return;
      _scrollCtrl.jumpTo(position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.current?.messages ?? [];
    if (chat.busy) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 智能答疑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: '新对话',
            onPressed: () {
              setState(() => _pendingImage = null);
              context.read<ChatProvider>().newSession();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '历史记录',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _Bubble(msg: messages[i]),
                  ),
          ),
          if (chat.busy)
            const LinearProgressIndicator(minHeight: 2, color: AppTheme.primary),
          _buildInputBar(chat.busy),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined,
              size: 64, color: AppTheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('你好，我是 AI 学习助手',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('可以问我题目，或拍下题目让我讲解',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _suggestionChip('一元二次方程怎么解？'),
              _suggestionChip('帮我批改一篇作文'),
              _suggestionChip('什么是牛顿第二定律？'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 13)),
      onPressed: () {
        _inputCtrl.text = text;
        _send();
      },
    );
  }

  Widget _buildInputBar(bool busy) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      color: AppTheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingImage != null) _pendingPreview(),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: _pendingImage == null
                      ? AppTheme.textSecondary
                      : AppTheme.primary,
                ),
                tooltip: '上传题目图片',
                onPressed: busy ? null : _chooseImage,
              ),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: '输入你的问题，或上传题目图片',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                onPressed: busy ? null : _send,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingPreview() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_pendingImage!),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => setState(() => _pendingImage = null),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: AppTheme.textPrimary,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    final chat = context.read<ChatProvider>();
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('历史对话',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...chat.sessions.map((s) => ListTile(
                title: Text(s.title),
                subtitle: Text(
                    '${s.messages.length} 条 · ${s.updateTime.toString().substring(0, 16)}'),
                onTap: () {
                  setState(() => _pendingImage = null);
                  chat.selectSession(s);
                  Navigator.pop(context);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  onPressed: () => chat.deleteSession(s.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isTyping && msg.content.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const SizedBox(
            width: 40,
            child: Row(children: [
              Dot(),
              SizedBox(width: 4),
              Dot(delay: 200),
              SizedBox(width: 4),
              Dot(delay: 400),
            ]),
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            bottomLeft: isUser ? null : Radius.zero,
          ),
          border: isUser ? null : Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imageUrl != null)
              Padding(
                padding: EdgeInsets.only(bottom: msg.content.isEmpty ? 0 : 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: Image.file(
                      File(msg.imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: isUser ? Colors.white70 : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            if (msg.content.isNotEmpty)
              Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.5,
                  fontSize: 14.5,
                ),
              ),
            if (!isUser && !msg.isTyping) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('收入错题本', style: TextStyle(fontSize: 12)),
                    onPressed: () => _addToWrong(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addToWrong(BuildContext context) {
    context.read<WrongQuestionProvider>().add(WrongQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          subject: '数学',
          question: msg.content.length > 60
              ? msg.content.substring(0, 60)
              : msg.content,
          userAnswer: '（来自 AI 答疑）',
          correctAnswer: '见 AI 解析',
          analysis: msg.content,
          errorType: '知识点盲区',
          createdAt: DateTime.now(),
        ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已加入错题本'), behavior: SnackBarBehavior.floating),
    );
  }
}

class Dot extends StatefulWidget {
  final int delay;
  const Dot({super.key, this.delay = 0});
  @override
  State<Dot> createState() => _DotState();
}

class _DotState extends State<Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
              color: AppTheme.textSecondary, shape: BoxShape.circle)),
    );
  }
}
