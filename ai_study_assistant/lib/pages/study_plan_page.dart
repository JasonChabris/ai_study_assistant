import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/plan_provider.dart';

class StudyPlanPage extends StatelessWidget {
  const StudyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('个性化学习计划')),
      body: plan.today == null
          ? _buildEmpty(context, plan)
          : RefreshIndicator(
              onRefresh: () => plan.generateTodayPlan(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (plan.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(plan.error!,
                          style: const TextStyle(color: AppTheme.error)),
                    ),
                  _buildHeader(context, plan),
                  const SizedBox(height: 16),
                  _buildWeakPoints(plan),
                  const SizedBox(height: 16),
                  _buildTaskList(context, plan),
                  const SizedBox(height: 16),
                  _buildCheckIn(context, plan),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, PlanProvider plan) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            plan.generating ? '正在生成今日计划，请稍等片刻' : 'AI 将根据你的学情生成今日计划',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (plan.error != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(plan.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.error)),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: plan.generating ? null : () => plan.generateTodayPlan(),
            icon: plan.generating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.psychology_outlined),
            label: const Text('生成今日计划'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlanProvider plan) {
    final progress = plan.totalCount == 0
        ? 0.0
        : plan.completedCount / plan.totalCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text('今日进度 ${plan.completedCount}/${plan.totalCount}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text('预计共 ${plan.today!.tasks.fold<int>(0, (s, t) => s + t.estimatedMinutes)} 分钟',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeakPoints(PlanProvider plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.trending_up_rounded, color: AppTheme.warning, size: 20),
            SizedBox(width: 8),
            Text('薄弱知识点',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.today!.weakPoints
                .map((w) => Chip(
                      label: Text(w, style: const TextStyle(fontSize: 13)),
                      backgroundColor: AppTheme.warning.withOpacity(0.1),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, PlanProvider plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('今日任务',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...plan.today!.tasks.asMap().entries.map((e) {
          final t = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: CheckboxListTile(
              value: t.completed,
              onChanged: (_) => plan.toggleTask(t.id),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                t.title,
                style: TextStyle(
                  decoration: t.completed ? TextDecoration.lineThrough : null,
                  color: t.completed ? AppTheme.textHint : AppTheme.textPrimary,
                ),
              ),
              subtitle: Text('${t.subject} · ${t.type} · 约 ${t.estimatedMinutes} 分钟'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCheckIn(BuildContext context, PlanProvider plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('学习打卡',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(14, (i) {
              final d = DateTime.now().subtract(Duration(days: 13 - i));
              final key =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              final checked = plan.checkIns.contains(key);
              final isToday = i == 13;
              return Container(
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? AppTheme.accent : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppTheme.primary, width: 1.5)
                      : null,
                ),
                child: Text('${d.day}',
                    style: TextStyle(
                        fontSize: 12,
                        color: checked ? Colors.white : AppTheme.textSecondary)),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: plan.isCheckedToday ? null : () => plan.checkIn(),
              icon: const Icon(Icons.fitness_center_rounded),
              label: Text(plan.isCheckedToday ? '今日已打卡 ✓' : '完成打卡'),
            ),
          ),
        ],
      ),
    );
  }
}
