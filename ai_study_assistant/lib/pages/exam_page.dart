import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/exam.dart';
import '../services/api_service.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _api = ApiService();
  final _rangeCtrl = TextEditingController();

  String _subject = '数学';
  String _grade = '高中';
  int _count = 5;
  String _difficulty = '中等';
  final Set<String> _types = {'选择'};

  List<ExamQuestion> _questions = [];
  bool _loading = false;
  bool _answered = false;
  String? _error;

  final _subjects = ['语文', '数学', '英语', '物理', '化学'];
  final _allTypes = ['选择', '填空', '简答', '计算'];
  final _difficulties = ['简单', '中等', '困难'];

  @override
  void dispose() {
    _rangeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_types.isEmpty) {
      setState(() => _error = '请至少选择一种题型。');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await _api.generateExam(ExamConfig(
        subject: _subject,
        grade: _grade,
        knowledgeRange: _rangeCtrl.text.trim(),
        count: _count,
        types: _types.toList(),
        difficulty: _difficulty,
      ));
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _loading = false;
          _error = '试题结果不完整，请再试一次。';
        });
        return;
      }
      setState(() {
        _questions = questions;
        _loading = false;
        _answered = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _objectiveTotal =>
      _questions.where((q) => q.type == '选择' || q.type == '填空').length;

  int get _correctCount {
    var count = 0;
    for (final q in _questions) {
      if (q.type == '选择' && q.userAnswer.trim().toUpperCase() == q.answer.trim().toUpperCase()) {
        count++;
      } else if (q.type == '填空' && _sameAnswer(q.userAnswer, q.answer)) {
        count++;
      }
    }
    return count;
  }

  bool _sameAnswer(String user, String answer) {
    final left = _normalize(user);
    final right = _normalize(answer);
    return left.isNotEmpty && left == right;
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'[\s，。、；;,.．]+'), '').toLowerCase();
  }

  String get _scoreLabel {
    if (_objectiveTotal == 0) return '主观题请对照解析';
    final base = '客观题 $_correctCount / $_objectiveTotal';
    if (_questions.length == _objectiveTotal) {
      return '得分 $_correctCount / $_objectiveTotal';
    }
    return '$base · 主观题请对照解析';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模拟试题'),
      ),
      body: _questions.isEmpty
          ? _buildConfig()
          : _buildExam(),
    );
  }

  Widget _buildConfig() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('试题参数配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
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
                items: ['初中', '高中', '大学']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _grade = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _rangeCtrl,
            decoration: const InputDecoration(
              labelText: '知识点范围',
              hintText: '如：函数与导数 / 力学 / 定语从句',
            ),
          ),
          const SizedBox(height: 16),
          const Text('题型', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allTypes.map((t) {
              final selected = _types.contains(t);
              return FilterChip(
                label: Text(t),
                selected: selected,
                onSelected: (s) => setState(() {
                  if (s) {
                    _types.add(t);
                  } else {
                    _types.remove(t);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('题目数量', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [5, 10, 15].map((n) => ChoiceChip(
                  label: Text('$n 题'),
                  selected: _count == n,
                  onSelected: (_) => setState(() => _count = n),
                )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('难度', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _difficulties.map((d) => ChoiceChip(
                  label: Text(d),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                )).toList(),
          ),
          const SizedBox(height: 28),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
          ],
          if (_loading) ...[
            const Text('正在出题，请稍等…',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('开始生成试题'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExam() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('共 ${_questions.length} 题 · $_difficulty',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              if (_answered)
                Flexible(
                  child: Text(_scoreLabel,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              TextButton(
                onPressed: () => setState(() {
                  _questions = [];
                  _answered = false;
                }),
                child: const Text('重新配置'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _questions.length,
            itemBuilder: (_, i) => _questionCard(_questions[i], i),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
          color: AppTheme.surface,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _answered = true),
              child: Text(_answered ? '查看解析完成' : '提交答卷'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(ExamQuestion q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              child: Text(q.type,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.subjectColor(q.subject))),
            ),
            const SizedBox(width: 8),
            Text('第 ${index + 1} 题',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 10),
          Text(q.stem, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 12),
          if (q.type == '选择')
            ...q.options.map((opt) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt, style: const TextStyle(fontSize: 14)),
                  value: opt.isEmpty ? '' : opt[0],
                  groupValue: q.userAnswer,
                  onChanged: _answered
                      ? null
                      : (v) => setState(() => q.userAnswer = v!),
                ))
          else
            TextField(
              maxLines: 3,
              enabled: !_answered,
              decoration: const InputDecoration(hintText: '在此作答...'),
              onChanged: (v) => q.userAnswer = v,
            ),
          if (_answered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('标准答案：${q.answer}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent)),
                  const SizedBox(height: 6),
                  Text(q.analysis,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
