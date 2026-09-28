import 'package:flutter/foundation.dart';
import '../models/study_plan.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class PlanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  DailyPlan? _today;
  List<String> _checkIns = [];
  bool _generating = false;
  String? _error;

  DailyPlan? get today => _today;
  List<String> get checkIns => List.unmodifiable(_checkIns);
  bool get generating => _generating;
  String? get error => _error;

  bool get isCheckedToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _checkIns.contains(today);
  }

  int get completedCount => _today?.tasks.where((t) => t.completed).length ?? 0;
  int get totalCount => _today?.tasks.length ?? 0;

  Future<void> load() async {
    _checkIns = await StorageService.getCheckIns();
    final list = await StorageService.getPlans();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (list != null) {
      for (final item in list) {
        final p = DailyPlan.fromJson(item);
        if (p.date == todayStr) {
          _today = p;
          break;
        }
      }
    }
    notifyListeners();
  }

  /// 根据学段、错题和已收藏知识点生成今日计划。
  Future<void> generateTodayPlan() async {
    if (_generating) return;
    _generating = true;
    _error = null;
    notifyListeners();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      _today = await _api.generateTodayPlan(
        date: todayStr,
        grade: await _grade(),
        hints: await _hints(),
      );
      await _persist();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<String> _grade() async {
    final user = await StorageService.getUserJson();
    final grade = user?['grade']?.toString() ?? '';
    return grade.isEmpty ? '高中' : grade;
  }

  Future<List<String>> _hints() async {
    final hints = <String>[];
    final wrong = await StorageService.getWrongQuestions() ?? [];
    for (final item in wrong) {
      if (hints.length >= 4 || item is! Map || item['mastered'] == true) continue;
      final subject = item['subject']?.toString() ?? '';
      final kind = item['errorType']?.toString() ?? '';
      final question = item['question']?.toString() ?? '';
      final brief = question.length > 12 ? question.substring(0, 12) : question;
      final hint = [subject, kind, brief].where((part) => part.isNotEmpty).join('·');
      if (hint.isNotEmpty) hints.add(hint);
    }
    final notes = await StorageService.getKnowledgeNotes() ?? [];
    for (final item in notes) {
      if (hints.length >= 6 || item is! Map) continue;
      final keyword = item['keyword']?.toString() ?? '';
      if (keyword.isEmpty) continue;
      final subject = item['subject']?.toString() ?? '';
      hints.add('已收藏$subject$keyword');
    }
    return hints;
  }

  Future<void> toggleTask(String id) async {
    final tasks = _today?.tasks;
    if (tasks == null) return;
    StudyTask? task;
    for (final item in tasks) {
      if (item.id == id) {
        task = item;
        break;
      }
    }
    if (task == null) return;
    final current = task;
    current.completed = !current.completed;
    await _persist();
    notifyListeners();
  }

  Future<void> addTask(StudyTask task) async {
    _today?.tasks.add(task);
    await _persist();
    notifyListeners();
  }

  Future<void> checkIn() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await StorageService.checkIn(todayStr);
    _checkIns.add(todayStr);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_today == null) return;
    await StorageService.savePlans([_today!.toJson()]);
  }
}
