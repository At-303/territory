import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/level.dart';

class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs)
      : completed = (_prefs.getStringList('completed') ?? const <String>[])
            .map(int.parse)
            .toSet(),
        lastLevel = _prefs.getInt('lastLevel') ?? 1;

  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore._(prefs);
  }

  final SharedPreferences _prefs;
  final Set<int> completed;
  int lastLevel;

  /// First level that has not been completed yet.
  int get nextLevel {
    for (var n = 1; n <= kLevelCount; n++) {
      if (!completed.contains(n)) return n;
    }
    return kLevelCount;
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
