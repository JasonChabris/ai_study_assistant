import 'package:flutter/foundation.dart';
import '../models/wrong_question.dart';
import '../services/storage_service.dart';

class WrongQuestionProvider extends ChangeNotifier {
  List<WrongQuestion> _items = [];
  String _filterSubject = '全部';
  String _filterErrorType = '全部';

  List<WrongQuestion> get items => List.unmodifiable(_items);
  String get filterSubject => _filterSubject;
  String get filterErrorType => _filterErrorType;

  List<WrongQuestion> get filtered {
    return _items.where((q) {
      final okSub = _filterSubject == '全部' || q.subject == _filterSubject;
      final okErr = _filterErrorType == '全部' || q.errorType == _filterErrorType;
      return okSub && okErr && !q.mastered;
    }).toList();
  }

  List<WrongQuestion> get masteredItems =>
      _items.where((q) => q.mastered).toList();

  /// 各学科错题数（用于统计）
  Map<String, int> get subjectCount {
    final m = <String, int>{};
    for (final q in _items) {
      m[q.subject] = (m[q.subject] ?? 0) + 1;
    }
    return m;
  }

  Future<void> load() async {
    final list = await StorageService.getWrongQuestions();
    if (list != null) {
      _items = list.map((e) => WrongQuestion.fromJson(e)).toList();
    }
    notifyListeners();
  }

  void setFilter(String subject, String errorType) {
    _filterSubject = subject;
    _filterErrorType = errorType;
    notifyListeners();
  }

  Future<void> add(WrongQuestion q) async {
    _items.insert(0, q);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleMastered(String id) async {
    final q = _items.firstWhere((e) => e.id == id);
    q.mastered = !q.mastered;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((q) => q.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearMastered() async {
    _items.removeWhere((q) => q.mastered);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.saveWrongQuestions(_items.map((q) => q.toJson()).toList());
  }
}
