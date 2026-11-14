import 'dart:async';

import 'package:flutter/foundation.dart';

import 'level.dart';
import 'rules.dart';

enum CheckResult { incomplete, wrong, solved }

class _Snapshot {
  _Snapshot(this.cells, this.activeClue);

  final List<int> cells;
  final int? activeClue;
}

/// Game state and rules. No widgets in here.
///
/// Flow: tap a numbered cell to pick its region, then tap or drag cells to
/// give them to that region (tap one of its cells again to remove it).
/// Nothing is rejected while painting. When every cell is filled, [isFull]
/// is true, the Check button appears, and [check] judges every region.
class GameController extends ChangeNotifier {
  GameController(this.level) {
    _reset();
  }

  final Level level;

  /// Owner of every cell: [kBlocked], [kEmpty], or a region id.
  late List<int> cells;

  /// Numbered cells by cell index.
  late Map<int, Clue> clueAt;

  /// Cells shown in red after a failed check.
  final Set<int> errorCells = {};

  /// Region id (clue index) being painted, or null.
  int? activeClue;

  /// Last feedback text (why a check failed).
  String message = '';

  int seconds = 0;
  bool paused = false;
  bool solved = false;
  bool showSymbols = true;

  final List<_Snapshot> _undo = [];
  bool _dragging = false;
  bool _strokeRecorded = false;
  Timer? _timer;

  int get totalRegions => level.clues.length;

  /// True when no cell is left empty. The Check button shows only then.
  bool get isFull => !cells.contains(kEmpty);

  /// Cells of the region being painted (drawn with a thicker border).
  Set<int> get selection {
    final a = activeClue;
    if (a == null) return const <int>{};
    return {
      for (var i = 0; i < cells.length; i++)
        if (cells[i] == a) i,
    };
  }

  /// Style (colour + symbol) of the region being painted.
  int get activeStyle {
    final a = activeClue;
    return a == null ? 0 : level.clues[a].style;
  }

  /// Regions that currently follow every rule (live counter).
  int get completedRegions {
    var count = 0;
    for (final clue in level.clues) {
      final members = _membersOf(clue.region);
      if (validateRegion(
        level: level,
        clue: clue,
        cells: members,
        owners: cells,
      ).isValid) {
        count++;
      }
    }
    return count;
  }

  bool get canUndo => _undo.isNotEmpty;

  Set<int> _membersOf(int region) => {
        for (var i = 0; i < cells.length; i++)
          if (cells[i] == region) i,
      };

  void _reset() {
    cells = List<int>.filled(level.size * level.size, kEmpty);
    for (final b in level.blocked) {
      cells[b] = kBlocked;
    }
    clueAt = level.clueByCell;
    // A numbered cell always belongs to its own region.
    for (final clue in level.clues) {
      cells[level.clueIndex(clue)] = clue.region;
    }
    errorCells.clear();
    activeClue = null;
    message = '';
    _undo.clear();
    _dragging = false;
    _strokeRecorded = false;
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

  /// Reset: restart the current puzzle.
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

  // ---------------------------------------------------------------- undo

  void _pushUndo() {
    _undo.add(_Snapshot(List<int>.of(cells), activeClue));
    if (_undo.length > 300) _undo.removeAt(0);
  }

  /// Reverses the previous action (a paint, an erase or a region switch).
  void undo() {
    if (_undo.isEmpty || solved) return;
    final s = _undo.removeLast();
    cells = List<int>.of(s.cells);
    activeClue = s.activeClue;
    errorCells.clear();
    message = '';
    notifyListeners();
  }

  // ------------------------------------------------------------ painting

  void _activate(int? region) {
    if (activeClue == region) return;
    _pushUndo();
    activeClue = region;
  }

  /// Give [index] to the active region. Numbered and blocked cells never
  /// change owner. Returns true if something changed.
  bool _paint(int index) {
    final region = activeClue;
    if (region == null) return false;
    if (cells[index] == kBlocked || clueAt.containsKey(index)) return false;
    if (cells[index] == region) return false;
    if (!_strokeRecorded) {
      _pushUndo();
      _strokeRecorded = true;
    }
    cells[index] = region;
    return true;
  }

  /// Tap a numbered cell to pick (or drop) its region; tap any other cell
  /// to give it to the active region, or to remove it if it is already there.
  void tap(int index) {
    if (solved || cells[index] == kBlocked) return;
    errorCells.clear();

    final clue = clueAt[index];
    if (clue != null) {
      _activate(activeClue == clue.region ? null : clue.region);
    } else {
      final region = activeClue;
      if (region == null) {
        notifyListeners();
        return;
      }
      _strokeRecorded = false;
      if (cells[index] == region) {
        _pushUndo();
        cells[index] = kEmpty;
      } else {
        _paint(index);
      }
    }
    notifyListeners();
  }

  /// Start a stroke from a numbered cell, a painted cell, or the active
  /// region. A whole stroke is one undo step.
  void beginDrag(int index) {
    if (solved || cells[index] == kBlocked) return;
    errorCells.clear();
    _strokeRecorded = false;

    final clue = clueAt[index];
    if (clue != null) {
      _activate(clue.region);
    } else if (cells[index] >= 0) {
      _activate(cells[index]);
    } else {
      _paint(index);
    }
    _dragging = activeClue != null;
    notifyListeners();
  }

  void dragTo(int index) {
    if (!_dragging || solved) return;
    if (_paint(index)) notifyListeners();
  }

  void endDrag() {
    _dragging = false;
    _strokeRecorded = false;
  }

  // ------------------------------------------------------------ checking

  /// Check button (only shown when [isFull]). Judges every region with
  /// [validateRegion]; wrong regions are put in [errorCells] and the first
  /// problem is in [message].
  CheckResult check() {
    if (solved) return CheckResult.solved;
    errorCells.clear();

    if (!isFull) {
      message = 'Fill every cell first.';
      notifyListeners();
      return CheckResult.incomplete;
    }

    String? firstProblem;
    for (final clue in level.clues) {
      final members = _membersOf(clue.region);
      final r = validateRegion(
        level: level,
        clue: clue,
        cells: members,
        owners: cells,
      );
      if (!r.isValid) {
        errorCells.addAll(members);
        firstProblem ??= r.message;
      }
    }

    if (firstProblem != null) {
      message = firstProblem;
      notifyListeners();
      return CheckResult.wrong;
    }

    solved = true;
    message = 'Puzzle solved!';
    notifyListeners();
    return CheckResult.solved;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}