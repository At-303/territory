import 'dart:async';

import 'package:flutter/foundation.dart';

import 'level.dart';

enum CheckResult { incomplete, wrong, solved }

class GameController extends ChangeNotifier {
  GameController(this.level) {
    _reset();
  }

  final Level level;

  /// kBlocked, kEmpty, or a region id per cell.
  late List<int> cells;
  late Map<int, Clue> clueAt;

  int seconds = 0;
  bool paused = false;
  bool solved = false;
  bool showSymbols = true;

  int? _activeRegion;
  Timer? _timer;

  void _reset() {
    cells = List<int>.filled(level.size * level.size, kEmpty);
    clueAt = {};
    for (final b in level.blocked) {
      cells[b] = kBlocked;
    }
    for (final clue in level.clues) {
      final i = level.index(clue.row, clue.col);
      cells[i] = clue.region;
      clueAt[i] = clue;
    }
    seconds = 0;
    solved = false;
    paused = false;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!paused && !solved) {
        seconds++;
        notifyListeners();
      }
    });
  }

  void restart() {
    _reset();
    notifyListeners();
  }

  void pause() {
    paused = true;
    notifyListeners();
  }

  void resume() {
    paused = false;
    notifyListeners();
  }

  void toggleSymbols() {
    showSymbols = !showSymbols;
    notifyListeners();
  }

  /// Start painting from a clue cell or an already painted cell.
  void beginDrag(int index) {
    if (solved) return;
    _activeRegion = cells[index] >= 0 ? cells[index] : null;
  }

  void dragTo(int index) {
    final region = _activeRegion;
    if (region == null || solved) return;
    if (cells[index] == kBlocked || clueAt.containsKey(index)) return;
    if (cells[index] == region) return;
    cells[index] = region;
    notifyListeners();
  }

  void endDrag() => _activeRegion = null;

  /// Tapping a painted (non-clue) cell erases it.
  void tap(int index) {
    if (solved) return;
    if (cells[index] >= 0 && !clueAt.containsKey(index)) {
      cells[index] = kEmpty;
      notifyListeners();
    }
  }

  CheckResult check() {
    if (cells.contains(kEmpty)) return CheckResult.incomplete;

    for (final clue in level.clues) {
      final start = level.index(clue.row, clue.col);
      final seen = <int>{start};
      final stack = <int>[start];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        for (final nb in gridNeighbors(cur, level.size)) {
          if (cells[nb] == clue.region && seen.add(nb)) stack.add(nb);
        }
      }
      final total = cells.where((v) => v == clue.region).length;
      if (seen.length != clue.size || total != clue.size) {
        return CheckResult.wrong;
      }
    }
    solved = true;
    notifyListeners();
    return CheckResult.solved;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
