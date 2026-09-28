import 'package:flutter/material.dart';

/// 应用主题：简约清新、低饱和护眼风格
class AppTheme {
  // 主色 - 清新蓝绿
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryLight = Color(0xFF6BA8E8);
  static const Color primaryDark = Color(0xFF2E6BB0);

  // 辅助色
  static const Color accent = Color(0xFF5BC8A6);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);

  // 背景色
  static const Color bg = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE8ECF1);

  // 文字色
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7A8A99);
  static const Color textHint = Color(0xFFB0BEC5);

  // 学科配色
  static const Map<String, Color> subjectColors = {
    '语文': Color(0xFFE57373),
    '数学': Color(0xFF4A90D9),
    '英语': Color(0xFF5BC8A6),
    '物理': Color(0xFFFFB74D),
    '化学': Color(0xFFBA68C8),
    '生物': Color(0xFF81C784),
    '历史': Color(0xFFA1887F),
    '地理': Color(0xFF4DD0E1),
    '政治': Color(0xFFF06292),
  };

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      dividerColor: divider,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 15),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 学科颜色
  static Color subjectColor(String subject) {
    return subjectColors[subject] ?? primary;
  }
}
