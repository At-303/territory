import 'package:flutter_test/flutter_test.dart';
import 'package:territory/game/game_controller.dart';
import 'package:territory/game/level.dart';

void main() {
  group('generateLevel', () {
    test('is deterministic', () {
      final a = generateLevel(9);
      final b = generateLevel(9);
      expect(a.solution, b.solution);
    });

    test('every level has clues that add up to the free cells', () {
      for (var n = 1; n <= kLevelCount; n++) {
        final level = generateLevel(n);
        final free = level.size * level.size - level.blocked.length;
        final total = level.clues.fold<int>(0, (sum, c) => sum + c.size);
        expect(total, free, reason: 'level $n');
      }
    });

    test('the generated solution passes check()', () {
      for (var n = 1; n <= kLevelCount; n++) {
        final game = GameController(generateLevel(n));
        game.cells = List<int>.from(game.level.solution);
        expect(game.check(), CheckResult.solved, reason: 'level $n');
        game.dispose();
      }
    });

    test('an empty board is incomplete', () {
      final game = GameController(generateLevel(1));
      expect(game.check(), CheckResult.incomplete);
      game.dispose();
    });
  });
}
