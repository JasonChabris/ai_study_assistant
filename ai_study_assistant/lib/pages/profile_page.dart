import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user?.nickname.substring(0, 1) ?? '游',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nickname ?? '未登录',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.grade ?? ''} · ${auth.isGuest ? '游客模式' : '已登录'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => _showEditDialog(context, auth),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _group([
            _Item(
              icon: Icons.sync_rounded,
              color: AppTheme.primary,
              title: '数据同步',
              subtitle: '三端数据实时同步',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已同步到云端')),
              ),
            ),
            _Item(
              icon: Icons.palette_outlined,
              color: AppTheme.accent,
              title: '学习阶段',
              subtitle: user?.grade ?? '未设置',
              onTap: () => _showGradeDialog(context, auth),
            ),
          ]),
          const SizedBox(height: 12),
          _group([
            _Item(
              icon: Icons.cleaning_services_outlined,
              color: AppTheme.warning,
              title: '清除本地缓存',
              subtitle: '删除本地对话、错题、笔记',
              onTap: () async {
                await StorageService.clearLocal();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('本地缓存已清除')),
                  );
                }
              },
            ),
            _Item(
              icon: Icons.shield_outlined,
              color: AppTheme.primary,
              title: '隐私设置',
              subtitle: '学习数据仅本人可见',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),
          _group([
            _Item(
              icon: Icons.info_outline_rounded,
              color: AppTheme.textSecondary,
              title: '关于我们',
              subtitle: 'AI 智能学习助手 v1.0.0',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'AI 智能学习助手',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '基于 Flutter 跨端开发，对接 Java 后端与 AI 大模型接口',
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: children),
    );
  }

  void _showEditDialog(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController(text: auth.user?.nickname);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              auth.updateProfile(nickname: ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showGradeDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择学习阶段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['小学', '初中', '高中', '大学']
              .map((g) => ListTile(
                    title: Text(g),
                    onTap: () {
                      auth.updateProfile(grade: g);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
