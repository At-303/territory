import 'package:flutter_test/flutter_test.dart';
import 'package:territory/game/game_controller.dart';
import 'package:territory/game/level.dart';
import 'package:territory/game/rules.dart';

/// 3x3 grid, three rows = three regions of 3, clues at cells 0, 3 and 6.
Level tinyLevel() => Level(
      number: 0,
      kind: Difficulty.easy,
      size: 3,
      blocked: <int>{},
      clues: const [
        Clue(row: 0, col: 0, size: 3, region: 0, style: 0),
        Clue(row: 1, col: 0, size: 3, region: 1, style: 1),
        Clue(row: 2, col: 0, size: 3, region: 2, style: 2),
      ],
      solution: const [0, 0, 0, 1, 1, 1, 2, 2, 2],
    );

/// Selects the solution's cells of [region] the way a player would.
void selectRegion(GameController g, int region) {
  final clueCell = g.level.clueIndex(g.level.clues[region]);
  g.tap(clueCell);
  for (var i = 0; i < g.level.solution.length; i++) {
    if (g.level.solution[i] == region && i != clueCell) g.tap(i);
  }
}

void main() {
  group('validateRegion', () {
    final level = tinyLevel();
    final clue = level.clues[1]; // cell 3, size 3
    final none = List<int>.filled(9, kEmpty);

    RegionValidation check(Set<int> cells, [List<int>? owners]) =>
        validateRegion(
          level: level,
          clue: clue,
          cells: cells,
          owners: owners ?? none,
        );

    test('accepts a correct region', () {
      expect(check({3, 4, 5}).isValid, isTrue);
    });

    test('missing numbered cell', () {
      expect(check({4, 5, 7}).error, RegionError.missingClue);
    });

    test('more than one number', () {
      expect(check({3, 6}).error, RegionError.multipleClues);
    });

    test('wrong size', () {
      expect(check({3, 4}).error, RegionError.wrongSize);
    });

    test('diagonal / split cells are not connected', () {
      expect(check({3, 5, 8}).error, RegionError.disconnected);
    });

    test('overlap with a confirmed region', () {
      final owners = List<int>.of(none)..[1] = 0;
      expect(check({3, 4, 1}, owners).error, RegionError.overlap);
    });
  });

  group('generator', () {
    test('is deterministic', () {
      final a = generateLevel(9);
      final b = generateLevel(9);
      expect(a.solution, b.solution);
      expect(a.clues.map((c) => c.row * 100 + c.col).toList(),
          b.clues.map((c) => c.row * 100 + c.col).toList());
    });

    test('difficulty sets the grid size', () {
      expect(generateLevel(1).size, 5);
      expect(generateLevel(7).size, 7);
      expect(generateLevel(13).size, 9);
      expect(generateLevel(19).size, 10);
    });

    test('every level follows the rules', () {
      for (var n = 1; n <= kLevelCount; n++) {
        final level = generateLevel(n);
        expect(PuzzleCheck.isValid(level), isTrue, reason: 'level $n');
        expect(level.blocked, isEmpty);
        expect(level.solution.contains(kEmpty), isFalse, reason: 'level $n');

        final total = level.clues.fold<int>(0, (sum, c) => sum + c.size);
        expect(total, level.size * level.size, reason: 'level $n');
        for (var i = 0; i < level.clues.length; i++) {
          expect(level.clues[i].region, i);
        }
      }
    });
  });

  group('GameController', () {
    test('confirming a correct region locks it', () {
      final g = GameController(tinyLevel());
      selectRegion(g, 0);
      expect(g.check(), CheckResult.incomplete);
      expect(g.cells.sublist(0, 3), [0, 0, 0]);
      expect(g.completedRegions, 1);
      expect(g.selection, isEmpty);
      expect(g.activeClue, isNull);
      g.dispose();
    });

    test('a wrong region turns red and stays editable', () {
      final g = GameController(tinyLevel());
      g.tap(3);
      g.tap(4); // only 2 cells, needs 3
      expect(g.check(), CheckResult.wrong);
      expect(g.errorCells, {3, 4});
      expect(g.message, contains('needs 3'));
      expect(g.cells[3], kEmpty);
      expect(g.selection, {3, 4});

      g.tap(5); // keep editing
      expect(g.errorCells, isEmpty);
      expect(g.check(), CheckResult.incomplete);
      expect(g.completedRegions, 1);
      g.dispose();
    });

    test('cells can be removed from the selection', () {
      final g = GameController(tinyLevel());
      g.tap(3);
      g.tap(4);
      g.tap(4);
      expect(g.selection, {3});
      g.dispose();
    });

    test('undo reverses selection and confirmation', () {
      final g = GameController(tinyLevel());
      selectRegion(g, 0);
      g.check();
      expect(g.completedRegions, 1);

      g.undo(); // the confirmation
      expect(g.completedRegions, 0);
      expect(g.selection, {0, 1, 2});

      g.undo(); // last tapped cell
      expect(g.selection, {0, 1});
      g.dispose();
    });

    test('solving every region wins', () {
      final g = GameController(tinyLevel());
      selectRegion(g, 0);
      expect(g.check(), CheckResult.incomplete);
      selectRegion(g, 1);
      expect(g.check(), CheckResult.incomplete);
      selectRegion(g, 2);
      expect(g.check(), CheckResult.solved);
      expect(g.solved, isTrue);
      g.dispose();
    });

    test('final check with unassigned cells is incomplete', () {
      final g = GameController(tinyLevel());
      selectRegion(g, 0);
      g.check();
      expect(g.check(), CheckResult.incomplete); // nothing selected
      expect(g.message, contains('not in a region'));
      g.dispose();
    });

    test('reset clears everything', () {
      final g = GameController(tinyLevel());
      selectRegion(g, 0);
      g.check();
      g.restart();
      expect(g.completedRegions, 0);
      expect(g.canUndo, isFalse);
      expect(g.cells.every((v) => v == kEmpty), isTrue);
      g.dispose();
    });

    test('dragging adds cells and is one undo step', () {
      final g = GameController(tinyLevel());
      g.beginDrag(3);
      g.dragTo(4);
      g.dragTo(5);
      g.endDrag();
      expect(g.selection, {3, 4, 5});
      g.undo();
      expect(g.selection, isEmpty);
      g.dispose();
    });

    test('a full generated level can be solved by its solution', () {
      final g = GameController(generateLevel(1));
      for (var r = 0; r < g.totalRegions; r++) {
        selectRegion(g, r);
        g.check();
      }
      expect(g.solved, isTrue);
      g.dispose();
    });
  });
}
