import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/knowledge_point.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final _api = ApiService();
  final _keywordCtrl = TextEditingController();
  String _subject = '数学';
  String _grade = '高中';
  bool _listView = true; // true=列表, false=思维导图
  bool _loading = false;
  bool _saved = false;
  String? _error;
  KnowledgeResult? _result;

  final _subjects = ['语文', '数学', '英语', '物理', '化学', '生物', '历史', '地理'];
  final _grades = ['初中', '高中', '大学'];

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.buildKnowledge(
        subject: _subject,
        grade: _grade,
        keyword: _keywordCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _saved = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saved) return;
    final list = await StorageService.getKnowledgeNotes() ?? [];
    final exists = list.any((item) => item is Map && item['id'] == result.id);
    if (!exists) {
      list.insert(0, result.toJson());
      await StorageService.saveKnowledgeNotes(list);
    }
    if (!mounted) return;
    setState(() => _saved = true);
    _toast(exists ? '已经收藏过了' : '已收藏到我的知识点');
  }

  Future<void> _showSaved() async {
    final raw = await StorageService.getKnowledgeNotes() ?? [];
    if (!mounted) return;
    final notes = raw
        .whereType<Map>()
        .map((item) => KnowledgeResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => notes.isEmpty
          ? const SizedBox(
              height: 160,
              child: Center(child: Text('还没有收藏的知识点')),
            )
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('我的知识点',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...notes.map((note) => ListTile(
                      title: Text('${note.subject} · ${note.keyword}'),
                      subtitle: Text(
                          '${note.grade} · ${note.createdAt.toString().substring(0, 16)}'),
                      onTap: () {
                        setState(() {
                          _result = note;
                          _saved = true;
                          _error = null;
                        });
                        Navigator.pop(ctx);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                        onPressed: () async {
                          final next = notes.where((n) => n.id != note.id).toList();
                          await StorageService.saveKnowledgeNotes(
                              next.map((n) => n.toJson()).toList());
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted && _result?.id == note.id) {
                            setState(() => _saved = false);
                          }
                          _showSaved();
                        },
                      ),
                    )),
              ],
            ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识点梳理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: '我的知识点',
            onPressed: _showSaved,
          ),
          if (_result != null)
            IconButton(
              icon: Icon(_listView ? Icons.account_tree : Icons.list_alt),
              tooltip: _listView ? '思维导图视图' : '列表视图',
              onPressed: () => setState(() => _listView = !_listView),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildConfigBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _result == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saved ? null : _save,
              icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_add_rounded),
              label: Text(_saved ? '已收藏' : '收藏'),
            ),
    );
  }

  Widget _buildConfigBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _subject,
                  decoration: const InputDecoration(labelText: '学科'),
                  items: _subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _subject = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _grade,
                  decoration: const InputDecoration(labelText: '年级'),
                  items: _grades
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _grade = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordCtrl,
                  decoration: const InputDecoration(
                    hintText: '输入知识点关键词，如：函数单调性',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('生成'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _result == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在梳理，请稍等片刻', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, size: 64, color: AppTheme.textHint),
            const SizedBox(height: 16),
            const Text('选择学科、输入知识点，AI 为你梳理框架',
                style: TextStyle(color: AppTheme.textSecondary)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ],
          ],
        ),
      );
    }
    final r = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${r.grade}${r.subject} · ${r.keyword}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(r.overview,
                style: const TextStyle(height: 1.6, color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 20),
          _listView
              ? _buildListView(r.nodes)
              : _buildTreeView(r.nodes),
          const SizedBox(height: 20),
          const Text('易错知识点汇总',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...r.mistakes.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m)),
                ]),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildListView(List<KnowledgeNode> nodes) {
    return Column(
      children: nodes.map((n) => _nodeCard(n, depth: 0)).toList(),
    );
  }

  Widget _nodeCard(KnowledgeNode n, {required int depth}) {
    Color levelColor = switch (n.level) {
      '重点' => AppTheme.primary,
      '难点' => AppTheme.error,
      _ => AppTheme.textSecondary,
    };
    return Container(
      margin: EdgeInsets.only(left: depth * 12, bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Expanded(child: Text(n.title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(n.level,
                    style: TextStyle(fontSize: 11, color: levelColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(n.detail,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
          ...n.children.map((c) => _nodeCard(c, depth: depth + 1)),
        ],
      ),
    );
  }

  Widget _buildTreeView(List<KnowledgeNode> nodes) {
    return Column(
      children: nodes.asMap().entries.map((e) {
        final i = e.key;
        final n = e.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.subjectColor(_subject),
                    shape: BoxShape.circle,
                  ),
                ),
                if (i != nodes.length - 1)
                  Container(width: 2, height: 60, color: AppTheme.divider),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...n.children.map((c) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('· ${c.title}：${c.detail}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                        )),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
