import 'package:flutter/foundation.dart';
import '../models/vocabulary.dart';
import '../services/storage_service.dart';

/// 学习工具：单词本 + 笔记 + 学习时长
class ToolsProvider extends ChangeNotifier {
  List<Word> _words = [];
  List<Note> _notes = [];
  Map<String, int> _studyMinutes = {};

  List<Word> get words => List.unmodifiable(_words);
  List<Note> get notes => List.unmodifiable(_notes);
  Map<String, int> get studyMinutes => Map.unmodifiable(_studyMinutes);

  /// 近 7 天学习时长
  List<MapEntry<String, int>> get last7Days {
    final now = DateTime.now();
    final list = <MapEntry<String, int>>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      list.add(MapEntry(key, _studyMinutes[key] ?? 0));
    }
    return list;
  }

  int get totalMinutes =>
      _studyMinutes.values.fold(0, (sum, v) => sum + v);

  Future<void> load() async {
    final w = await StorageService.getWords();
    if (w != null) _words = w.map((e) => Word.fromJson(e)).toList();
    final n = await StorageService.getNotes();
    if (n != null) _notes = n.map((e) => Note.fromJson(e)).toList();
    _studyMinutes = await StorageService.getStudyMinutes();
    notifyListeners();
  }

  // ---- 单词 ----
  Future<void> addWord(Word w) async {
    _words.add(w);
    await _persistWords();
    notifyListeners();
  }

  Future<void> reviewWord(String word) async {
    final w = _words.firstWhere((e) => e.word == word);
    w.reviewCount++;
    await _persistWords();
    notifyListeners();
  }

  Future<void> _persistWords() async {
    await StorageService.saveWords(_words.map((e) => e.toJson()).toList());
  }

  // ---- 笔记 ----
  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> _persistNotes() async {
    await StorageService.saveNotes(_notes.map((n) => n.toJson()).toList());
  }

  // ---- 学习时长 ----
  Future<void> addStudyMinutes(int minutes) async {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await StorageService.addStudyMinutes(key, minutes);
    _studyMinutes[key] = (_studyMinutes[key] ?? 0) + minutes;
    notifyListeners();
  }
}
