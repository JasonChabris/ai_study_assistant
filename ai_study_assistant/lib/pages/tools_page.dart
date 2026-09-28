import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tools_provider.dart';
import '../models/vocabulary.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习工具'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: '单词背诵'),
            Tab(icon: Icon(Icons.note_alt_outlined), text: '备忘录'),
            Tab(icon: Icon(Icons.timer_outlined), text: '计时器'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _VocabularyTab(),
          _NoteTab(),
          _TimerTab(),
        ],
      ),
    );
  }
}

// ---------------- 单词背诵 ----------------
class _VocabularyTab extends StatelessWidget {
  const _VocabularyTab();

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<ToolsProvider>();
    final words = tools.words;
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('今日词库为空，点击添加开始背单词',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addSampleWords(context),
              icon: const Icon(Icons.download_rounded),
              label: const Text('导入示例词库'),
            ),
          ],
        ),
      );
    }
    return PageView.builder(
      itemCount: words.length,
      itemBuilder: (_, i) {
        final w = words[i];
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(w.word,
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(w.phonetic,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              Text(w.meaning,
                  style: const TextStyle(fontSize: 18, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(w.example,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        context.read<ToolsProvider>().reviewWord(w.word),
                    child: const Text('认识'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error),
                    child: const Text('再背一次'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('已复习 ${w.reviewCount} 次',
                  style: const TextStyle(
                      color: AppTheme.textHint, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  void _addSampleWords(BuildContext context) {
    final samples = [
      Word(word: 'abandon', phonetic: '/əˈbændən/', meaning: 'v. 放弃；抛弃', example: 'He had to abandon his car in the snow.'),
      Word(word: 'benefit', phonetic: '/ˈbenɪfɪt/', meaning: 'n. 利益 v. 受益', example: 'The new policy will benefit students.'),
      Word(word: 'crucial', phonetic: '/ˈkruːʃl/', meaning: 'adj. 至关重要的', example: 'This is a crucial moment for our team.'),
      Word(word: 'diligent', phonetic: '/ˈdɪlɪdʒənt/', meaning: 'adj. 勤奋的', example: 'She is a diligent student.'),
      Word(word: 'efficient', phonetic: '/ɪˈfɪʃnt/', meaning: 'adj. 高效的', example: 'We need a more efficient way.'),
    ];
    for (final w in samples) {
      context.read<ToolsProvider>().addWord(w);
    }
  }
}

// ---------------- 备忘录 ----------------
class _NoteTab extends StatelessWidget {
  const _NoteTab();

  @override
  Widget build(BuildContext context) {
    final tools = context.watch<ToolsProvider>();
    final notes = tools.notes;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNote(context),
        icon: const Icon(Icons.add),
        label: const Text('记笔记'),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text('还没有笔记，点击右下角记录学习要点',
                  style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final n = notes[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.textHint),
                            onPressed: () =>
                                context.read<ToolsProvider>().deleteNote(n.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(n.content,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddNote(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建笔记'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题')),
            const SizedBox(height: 10),
            TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '内容')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              context.read<ToolsProvider>().addNote(Note(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    createdAt: DateTime.now(),
                  ));
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// ---------------- 计时器 ----------------
class _TimerTab extends StatefulWidget {
  const _TimerTab();

  @override
  State<_TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<_TimerTab> {
  int _totalSeconds = 25 * 60; // 默认番茄钟 25 分钟
  int _remaining = 25 * 60;
  Timer? _timer;
  bool _running = false;

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 0) {
          t.cancel();
          setState(() => _running = false);
          context.read<ToolsProvider>().addStudyMinutes(_totalSeconds ~/ 60);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('专注完成，已记录学习时长！')),
          );
        } else {
          setState(() => _remaining--);
        }
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _totalSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220, height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220, height: 220,
                  child: CircularProgressIndicator(
                    value: _totalSeconds == 0 ? 0 : _remaining / _totalSeconds,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Text('$mm:$ss',
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 28),
                onPressed: _reset,
              ),
              const SizedBox(width: 20),
              FloatingActionButton.large(
                onPressed: _toggle,
                child: Icon(_running ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 20),
              PopupMenuButton<int>(
                icon: const Icon(Icons.timelapse_rounded, size: 28),
                onSelected: (min) {
                  setState(() {
                    _totalSeconds = min * 60;
                    _remaining = _totalSeconds;
                  });
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 15, child: Text('15 分钟')),
                  const PopupMenuItem(value: 25, child: Text('25 分钟')),
                  const PopupMenuItem(value: 45, child: Text('45 分钟')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('专注学习 / 刷题计时',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
