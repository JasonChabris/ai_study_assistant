import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/exam.dart';
import '../models/knowledge_point.dart';
import '../models/study_plan.dart';

/// 智能答疑、知识点梳理、模拟试题对接本机 BIgModelAPI（Spring Boot + 智谱 GLM）。
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 300),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// 可用 `--dart-define=API_BASE_URL=http://192.168.x.x:8080` 覆盖。
  /// Android 模拟器访问本机服务要用 10.0.2.2。
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  /// 对接 `POST /api/chat` 的 SSE，按模型吐出的片段逐段返回。
  /// [imageBase64] 是题目图片，和 [mime] 一起交给多模态模型。
  Stream<String> askQuestion(
    String question, {
    List<Map<String, dynamic>> history = const [],
    String? imageBase64,
    String mime = 'image/jpeg',
  }) async* {
    try {
      final data = <String, dynamic>{
        'message': question,
        'history': history,
      };
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        data['image'] = imageBase64;
        data['mime'] = mime;
      }
      final resp = await _dio.post<ResponseBody>(
        '/api/chat',
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {Headers.acceptHeader: 'text/event-stream'},
        ),
      );
      final body = resp.data;
      if (body == null) {
        yield '模型没有返回内容，请再试一次。';
        return;
      }
      yield* _sseData(body.stream);
    } on DioException catch (e) {
      yield _offlineMessage(e);
    }
  }

  /// 对接 `POST /api/knowledge`，返回可展开的知识点结构。
  Future<KnowledgeResult> buildKnowledge({
    required String subject,
    required String grade,
    required String keyword,
  }) async {
    final data = await _postJson('/api/knowledge', {
      'subject': subject,
      'grade': grade,
      'keyword': keyword,
    });
    return KnowledgeResult.fromJson(data);
  }

  /// 对接 `POST /api/exam`，按题型、数量和难度出题。
  Future<List<ExamQuestion>> generateExam(ExamConfig config) async {
    final data = await _postJson('/api/exam', {
      'subject': config.subject,
      'grade': config.grade,
      'knowledgeRange': config.knowledgeRange,
      'count': config.count,
      'types': config.types,
      'difficulty': config.difficulty,
    });
    final list = data['questions'];
    if (list is! List || list.isEmpty) {
      throw Exception('试题结果不完整，请再试一次。');
    }
    return list
        .whereType<Map>()
        .map((item) => ExamQuestion.fromJson(Map<String, dynamic>.from(item)))
        .where((q) => q.stem.trim().isNotEmpty)
        .toList();
  }

  /// 对接 `POST /api/plan`，按学段和近期学情生成今日任务。
  Future<DailyPlan> generateTodayPlan({
    required String date,
    required String grade,
    required List<String> hints,
  }) async {
    final data = await _postJson('/api/plan', {
      'grade': grade,
      'hints': hints,
    });
    final rawTasks = data['tasks'];
    if (rawTasks is! List || rawTasks.isEmpty) {
      throw Exception('学习计划不完整，请再试一次。');
    }
    final tasks = rawTasks
        .whereType<Map>()
        .map((item) => StudyTask.fromJson(Map<String, dynamic>.from(item)))
        .where((task) => task.title.trim().isNotEmpty)
        .toList();
    if (tasks.isEmpty) {
      throw Exception('学习计划不完整，请再试一次。');
    }
    return DailyPlan(
      date: date,
      weakPoints: (data['weakPoints'] as List?)?.map((item) => item.toString()).toList() ?? [],
      tasks: tasks,
    );
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(receiveTimeout: const Duration(seconds: 55)),
      );
      final data = resp.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('模型没有返回内容，请再试一次。');
    } on DioException catch (e) {
      throw Exception(_offlineMessage(e));
    }
  }

  String _offlineMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return '暂时连不上学习助手后端（$apiBaseUrl）。请先在本机启动 BIgModelAPI。';
  }

  Stream<String> _sseData(Stream<List<int>> bytes) async* {
    final pending = StringBuffer();
    var emitted = false;
    try {
      await for (final piece in utf8.decoder.bind(bytes)) {
        pending.write(piece);
        final text = pending.toString().replaceAll('\r\n', '\n');
        pending
          ..clear()
          ..write(text);
        while (true) {
          final raw = pending.toString();
          final sep = raw.indexOf('\n\n');
          if (sep < 0) break;
          final event = raw.substring(0, sep);
          pending
            ..clear()
            ..write(raw.substring(sep + 2));
          final data = _eventText(event);
          if (data == null || data.isEmpty) continue;
          emitted = true;
          yield data;
        }
      }
    } catch (_) {
      if (emitted) return;
      rethrow;
    }
    final tail = _eventText(pending.toString());
    if (tail != null && tail.isNotEmpty) yield tail;
  }

  /// 取出一条 SSE 事件里的 data。没有 data 行时返回 null。
  String? _eventText(String raw) {
    if (raw.trim().isEmpty) return null;
    final parts = <String>[];
    var sawData = false;
    for (final line in raw.split('\n')) {
      if (!line.startsWith('data:')) continue;
      sawData = true;
      var value = line.substring(5);
      if (value.startsWith(' ')) value = value.substring(1);
      parts.add(value);
    }
    if (!sawData) return null;
    return parts.join('\n');
  }
}
