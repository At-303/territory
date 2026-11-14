import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/level.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs)
      : completed = (_prefs.getStringList('completed') ?? const <String>[])
            .map(int.parse)
            .toSet(),
        lastLevel = _prefs.getInt('lastLevel') ?? 1,
        darkMode = _prefs.getBool('darkMode') ?? false;

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore._(prefs);
  }

  final SharedPreferences _prefs;
  final Set<int> completed;
  int lastLevel;
  bool darkMode;

Future<void> toggleDark() async {
    darkMode = !darkMode;
    await _prefs.setBool('darkMode', darkMode);
    notifyListeners();
  }
  /// First level that has not been completed yet.
  int get nextLevel {
    for (var n = 1; n <= kLevelCount; n++) {
      if (!completed.contains(n)) return n;
    }
    return kLevelCount;
  }

 /// First unfinished level of [d]; the first level of [d] if all are done.
  int nextLevelIn(Difficulty d) {
    for (var n = d.firstLevel; n <= d.lastLevel; n++) {
      if (!completed.contains(n)) return n;
    }
    return d.firstLevel;
  }

  Future<void> markCompleted(int level) async {
    completed.add(level);
    await _prefs.setStringList(
      'completed',
      completed.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> setLast(int level) async {
    lastLevel = level;
    await _prefs.setInt('lastLevel', level);
  }
}
