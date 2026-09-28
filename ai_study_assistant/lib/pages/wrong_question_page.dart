import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/wrong_question_provider.dart';
import '../models/wrong_question.dart';

class WrongQuestionPage extends StatefulWidget {
  const WrongQuestionPage({super.key});

  @override
  State<WrongQuestionPage> createState() => _WrongQuestionPageState();
}

class _WrongQuestionPageState extends State<WrongQuestionPage> {
  final _subjects = ['全部', '语文', '数学', '英语', '物理', '化学'];
  final _errorTypes = ['全部', '概念错误', '计算失误', '审题不清', '知识点盲区'];
  String _subject = '全部';
  String _errorType = '全部';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WrongQuestionProvider>();
    final list = provider.filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能错题本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空已掌握',
            onPressed: () => provider.clearMastered(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cleaning_services_outlined,
                            size: 64, color: AppTheme.textHint),
                        SizedBox(height: 16),
                        Text('暂无待复盘的错题',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _card(list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(
                labelText: '学科',
                isDense: true,
              ),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                setState(() => _subject = v!);
                context
                    .read<WrongQuestionProvider>()
                    .setFilter(_subject, _errorType);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _errorType,
              decoration: const InputDecoration(
                labelText: '错误类型',
                isDense: true,
              ),
              items: _errorTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                setState(() => _errorType = v!);
                context
                    .read<WrongQuestionProvider>()
                    .setFilter(_subject, _errorType);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(WrongQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.subjectColor(q.subject).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(q.subject,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.subjectColor(q.subject))),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(q.errorType,
                  style: const TextStyle(fontSize: 12, color: AppTheme.error)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppTheme.textHint),
              onPressed: () =>
                  context.read<WrongQuestionProvider>().remove(q.id),
            ),
          ]),
          const SizedBox(height: 8),
          Text(q.question,
              style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('查看解析'),
                onPressed: () => _showAnalysis(q),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<WrongQuestionProvider>().toggleMastered(q.id),
                child: const Text('已掌握',
                    style: TextStyle(color: AppTheme.accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnalysis(WrongQuestion q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('题目：${q.question}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('你的答案：${q.userAnswer}',
                style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 8),
            Text('正确答案：${q.correctAnswer}',
                style: const TextStyle(color: AppTheme.accent)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('解析',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(q.analysis,
                style: const TextStyle(height: 1.6, color: AppTheme.textSecondary)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('手动添加错题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: qCtrl,
                decoration: const InputDecoration(labelText: '题目')),
            const SizedBox(height: 10),
            TextField(
                controller: aCtrl,
                decoration: const InputDecoration(labelText: '正确答案')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              context.read<WrongQuestionProvider>().add(WrongQuestion(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    subject: '数学',
                    question: qCtrl.text,
                    userAnswer: '（未记录）',
                    correctAnswer: aCtrl.text,
                    analysis: '手动添加，后续可补充解析。',
                    errorType: '知识点盲区',
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
