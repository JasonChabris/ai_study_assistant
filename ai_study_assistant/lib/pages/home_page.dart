import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tools_provider.dart';
import '../providers/wrong_question_provider.dart';
import 'ai_chat_page.dart';
import 'knowledge_page.dart';
import 'exam_page.dart';
import 'wrong_question_page.dart';
import 'study_plan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tools = context.watch<ToolsProvider>();
    final wq = context.watch<WrongQuestionProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, auth)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  _FeatureCard(
                    title: 'AI 智能答疑',
                    subtitle: '提问 · 拍照搜题 · 作文批改',
                    icon: Icons.chat_bubble_rounded,
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AiChatPage())),
                  ),
                  _FeatureCard(
                    title: '知识点梳理',
                    subtitle: '思维导图 · 重点难点',
                    icon: Icons.account_tree_rounded,
                    color: AppTheme.accent,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const KnowledgePage())),
                  ),
                  _FeatureCard(
                    title: '模拟试题',
                    subtitle: 'AI 出题 · 在线作答',
                    icon: Icons.quiz_rounded,
                    color: AppTheme.warning,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ExamPage())),
                  ),
                  _FeatureCard(
                    title: '错题本',
                    subtitle: '${wq.filtered.length} 道待复盘',
                    icon: Icons.bookmark_rounded,
                    color: AppTheme.error,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WrongQuestionPage())),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _StudyPlanCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _buildStatsCard(tools, wq),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: const Icon(Icons.person_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你好，${auth.user?.nickname ?? '同学'} 👋',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text('今天也要加油学习哦',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ToolsProvider tools, WrongQuestionProvider wq) {
    final minutes = tools.totalMinutes;
    final hours = (minutes / 60).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('累计学习', '$hours h'),
          _divider(),
          _statItem('错题本', '${wq.items.length} 道'),
          _divider(),
          _statItem('连续打卡', '${tools.studyMinutes.length} 天'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.white24);

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StudyPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StudyPlanPage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppTheme.accent, size: 30),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日学习计划',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('查看 AI 为你定制的每日任务与打卡',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
