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

/// Paints the solution's cells of [region] the way a player would.
void paintRegion(GameController g, int region) {
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
    test('numbered cells start in their own region', () {
      final g = GameController(tinyLevel());
      expect(g.cells[0], 0);
      expect(g.cells[3], 1);
      expect(g.cells[6], 2);
      expect(g.isFull, isFalse);
      g.dispose();
    });

    test('tap paints the active region and tapping again erases', () {
      final g = GameController(tinyLevel());
      g.tap(1); // no region picked yet: ignored
      expect(g.cells[1], kEmpty);

      g.tap(0); // pick region 0
      g.tap(1);
      expect(g.cells[1], 0);
      g.tap(1);
      expect(g.cells[1], kEmpty);
      g.dispose();
    });

    test('a numbered cell never changes owner', () {
      final g = GameController(tinyLevel());
      g.tap(0);
      g.tap(3); // picks region 1, does not paint
      expect(g.cells[3], 1);
      expect(g.activeClue, 1);
      g.dispose();
    });

    test('painting over another region takes the cell', () {
      final g = GameController(tinyLevel());
      g.tap(0);
      g.tap(4);
      expect(g.cells[4], 0);
      g.tap(3);
      g.tap(4);
      expect(g.cells[4], 1);
      g.dispose();
    });

    test('check is refused while cells are empty', () {
      final g = GameController(tinyLevel());
      paintRegion(g, 0);
      expect(g.isFull, isFalse);
      expect(g.check(), CheckResult.incomplete);
      expect(g.message, contains('Fill every cell'));
      g.dispose();
    });

    test('filling everything correctly wins', () {
      final g = GameController(tinyLevel());
      paintRegion(g, 0);
      paintRegion(g, 1);
      paintRegion(g, 2);
      expect(g.isFull, isTrue);
      expect(g.completedRegions, 3);
      expect(g.check(), CheckResult.solved);
      expect(g.solved, isTrue);
      g.dispose();
    });

    test('wrong regions turn red, right ones do not', () {
      final g = GameController(tinyLevel());
      // region 0 gets 4 cells, region 1 gets 2, region 2 is right.
      g.tap(0);
      g.tap(1);
      g.tap(2);
      g.tap(4);
      g.tap(3);
      g.tap(5);
      paintRegion(g, 2);
      expect(g.isFull, isTrue);

      expect(g.check(), CheckResult.wrong);
      expect(g.errorCells, {0, 1, 2, 4, 3, 5});
      expect(g.message, contains('needs 3'));
      expect(g.solved, isFalse);

      g.tap(0); // next interaction clears the red
      expect(g.errorCells, isEmpty);
      g.dispose();
    });

    test('undo reverses paints and region switches', () {
      final g = GameController(tinyLevel());
      g.tap(0); // switch
      g.tap(1); // paint
      expect(g.cells[1], 0);

      g.undo();
      expect(g.cells[1], kEmpty);
      expect(g.activeClue, 0);

      g.undo();
      expect(g.activeClue, isNull);
      expect(g.canUndo, isFalse);
      g.dispose();
    });

    test('dragging paints cells and is one undo step', () {
      final g = GameController(tinyLevel());
      g.beginDrag(3);
      g.dragTo(4);
      g.dragTo(5);
      g.endDrag();
      expect(g.cells.sublist(3, 6), [1, 1, 1]);

      g.undo(); // the stroke
      expect(g.cells[4], kEmpty);
      expect(g.cells[5], kEmpty);
      g.dispose();
    });

    test('reset clears everything', () {
      final g = GameController(tinyLevel());
      paintRegion(g, 0);
      g.restart();
      expect(g.cells[1], kEmpty);
      expect(g.activeClue, isNull);
      expect(g.canUndo, isFalse);
      g.dispose();
    });

    test('a generated level is solved by painting its solution', () {
      for (final n in [1, 7, 13, 19]) {
        final g = GameController(generateLevel(n));
        for (var r = 0; r < g.totalRegions; r++) {
          paintRegion(g, r);
        }
        expect(g.check(), CheckResult.solved, reason: 'level $n');
        g.dispose();
      }
    });
  });
}