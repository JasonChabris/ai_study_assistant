import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务：统一封装 SharedPreferences，支持 JSON 读写
class StorageService {
  static const _kUser = 'user';
  static const _kToken = 'token';
  static const _kChatSessions = 'chat_sessions';
  static const _kWrongQuestions = 'wrong_questions';
  static const _kPlans = 'study_plans';
  static const _kWords = 'words';
  static const _kNotes = 'notes';
  static const _kKnowledge = 'knowledge_notes';
  static const _kStudyMinutes = 'study_minutes'; // 每日学习时长 key:date
  static const _kCheckIns = 'check_ins'; // 打卡日期集合

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---- 通用读写 ----
  static Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  static Future<void> setJson(String key, Object value) async {
    await setString(key, jsonEncode(value));
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    final str = await getString(key);
    if (str == null || str.isEmpty) return null;
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final str = await getString(key);
    if (str == null || str.isEmpty) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  // ---- 业务键快捷方法 ----
  static Future<void> saveUserJson(Map<String, dynamic> json) =>
      setJson(_kUser, json);
  static Future<Map<String, dynamic>?> getUserJson() => getJsonMap(_kUser);

  static Future<void> saveToken(String? token) async {
    final p = await prefs;
    if (token == null) {
      await p.remove(_kToken);
    } else {
      await p.setString(_kToken, token);
    }
  }

  static Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(_kToken);
  }

  static Future<void> saveChatSessions(List<dynamic> list) =>
      setJson(_kChatSessions, list);
  static Future<List<dynamic>?> getChatSessions() => getJsonList(_kChatSessions);

  static Future<void> saveWrongQuestions(List<dynamic> list) =>
      setJson(_kWrongQuestions, list);
  static Future<List<dynamic>?> getWrongQuestions() => getJsonList(_kWrongQuestions);

  static Future<void> savePlans(List<dynamic> list) => setJson(_kPlans, list);
  static Future<List<dynamic>?> getPlans() => getJsonList(_kPlans);

  static Future<void> saveWords(List<dynamic> list) => setJson(_kWords, list);
  static Future<List<dynamic>?> getWords() => getJsonList(_kWords);

  static Future<void> saveNotes(List<dynamic> list) => setJson(_kNotes, list);
  static Future<List<dynamic>?> getNotes() => getJsonList(_kNotes);

  static Future<void> saveKnowledgeNotes(List<dynamic> list) =>
      setJson(_kKnowledge, list);
  static Future<List<dynamic>?> getKnowledgeNotes() => getJsonList(_kKnowledge);

  static Future<void> addStudyMinutes(String date, int minutes) async {
    final p = await prefs;
    final map = p.getString(_kStudyMinutes);
    Map<String, dynamic> data = {};
    if (map != null) data = jsonDecode(map);
    data[date] = (data[date] ?? 0) + minutes;
    await p.setString(_kStudyMinutes, jsonEncode(data));
  }

  static Future<Map<String, int>> getStudyMinutes() async {
    final p = await prefs;
    final map = p.getString(_kStudyMinutes);
    if (map == null) return {};
    final decoded = jsonDecode(map) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Future<void> checkIn(String date) async {
    final p = await prefs;
    final list = p.getStringList(_kCheckIns) ?? [];
    if (!list.contains(date)) {
      list.add(date);
      await p.setStringList(_kCheckIns, list);
    }
  }

  static Future<List<String>> getCheckIns() async {
    final p = await prefs;
    return p.getStringList(_kCheckIns) ?? [];
  }

  /// 清除本地缓存（隐私设置）
  static Future<void> clearLocal() async {
    final p = await prefs;
    await p.remove(_kChatSessions);
    await p.remove(_kWrongQuestions);
    await p.remove(_kNotes);
    await p.remove(_kKnowledge);
    await p.remove(_kStudyMinutes);
  }
}
