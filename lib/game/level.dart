import 'dart:math';

import 'rules.dart';

const int kEmpty = -1;
const int kBlocked = -2;

/// Levels per difficulty. Levels 1-6 easy, 7-12 medium, 13-18 hard, 19-24 expert.
const int kLevelsPerDifficulty = 6;
const int kLevelCount = 24;

enum Difficulty {
  easy(5),
  medium(7),
  hard(9),
  expert(10);

  const Difficulty(this.gridSize);

  /// Grid is gridSize x gridSize.
  final int gridSize;

  String get label => name;
  String get title => name[0].toUpperCase() + name.substring(1);

  int get firstLevel => index * kLevelsPerDifficulty + 1;
  int get lastLevel => firstLevel + kLevelsPerDifficulty - 1;

  static Difficulty forLevel(int number) {
    final i = ((number - 1) ~/ kLevelsPerDifficulty).clamp(0, 3);
    return Difficulty.values[i];
  }

  /// Region size range used by the generator. Grid size is not the only
  /// thing that changes: bigger regions mean fewer clues and more
  /// possibilities, and [tier] (0..5, position inside the difficulty)
  /// pushes the maximum region size up a little.
  (int, int) regionRange(int tier) {
    switch (this) {
      case Difficulty.easy:
        return (2, 4 + tier ~/ 3);
      case Difficulty.medium:
        return (3, 6 + tier ~/ 3);
      case Difficulty.hard:
        return (3, 8 + tier ~/ 3);
      case Difficulty.expert:
        return (4, 9 + tier ~/ 2);
    }
  }
}

/// Orthogonal neighbours of cell [i] on a [size] x [size] grid.
List<int> gridNeighbors(int i, int size) {
  final r = i ~/ size;
  final c = i % size;
  return [
    if (r > 0) i - size,
    if (r < size - 1) i + size,
    if (c > 0) i - 1,
    if (c < size - 1) i + 1,
  ];
}

class Clue {
  const Clue({
    required this.row,
    required this.col,
    required this.size,
    required this.region,
    required this.style,
  });

  final int row;
  final int col;

  /// Number shown on the cell = how many cells the region must contain.
  final int size;

  /// Region id. Always equal to this clue's position in [Level.clues].
  final int region;

  /// 0..4 -> colour + symbol (square, circle, triangle, heart, sparkle).
  final int style;
}

class Level {
  Level({
    required this.number,
    required this.kind,
    required this.size,
    required this.blocked,
    required this.clues,
    required this.solution,
  }) : clueByCell = {for (final c in clues) c.row * size + c.col: c};

  final int number;
  final Difficulty kind;
  final int size;

  /// Cells that are not part of the puzzle. Generated levels have none,
  /// because every cell must belong to a region.
  final Set<int> blocked;
  final List<Clue> clues;

  /// Clue by cell index.
  final Map<int, Clue> clueByCell;

  /// One valid solution: a region id per cell.
  final List<int> solution;

  String get difficulty => kind.label;

  int index(int r, int c) => r * size + c;
  int clueIndex(Clue c) => c.row * size + c.col;
}

/// Level [number] (1..24): its difficulty and tier come from the number,
/// and the puzzle is the same every time.
Level generateLevel(int number) {
  final kind = Difficulty.forLevel(number);
  return generatePuzzle(
    kind,
    seed: number * 7919 + 17,
    tier: (number - 1) % kLevelsPerDifficulty,
    number: number,
  );
}

/// Builds a puzzle from a random solution, so it always has at least one
/// valid solution. Each result is re-checked with [PuzzleCheck] (the same
/// validator the game uses) before it is returned. Use a new [seed] for a
/// new random puzzle.
Level generatePuzzle(
  Difficulty kind, {
  required int seed,
  int tier = 0,
  int number = 0,
}) {
  for (var attempt = 0;; attempt++) {
    final level = _build(kind, seed + attempt * 104729, tier, number);
    if (PuzzleCheck.isValid(level) || attempt >= 20) return level;
  }
}

Level _build(Difficulty kind, int seed, int tier, int number) {
  final size = kind.gridSize;
  final rnd = Random(seed);
  final (minS, maxS) = kind.regionRange(tier);

  final regions = _partition(size, rnd, minS, maxS);

  final owner = List<int>.filled(size * size, kEmpty);
  for (var id = 0; id < regions.length; id++) {
    for (final c in regions[id]) {
      owner[c] = id;
    }
  }

  // Give neighbouring regions different styles where possible.
  final styles = List<int>.filled(regions.length, -1);
  for (var id = 0; id < regions.length; id++) {
    final used = <int>{};
    for (final cell in regions[id]) {
      for (final nb in gridNeighbors(cell, size)) {
        final other = owner[nb];
        if (other != id && styles[other] >= 0) used.add(styles[other]);
      }
    }
    var s = 0;
    while (s < 5 && used.contains(s)) {
      s++;
    }
    styles[id] = s < 5 ? s : id % 5;
  }

  // One clue (the region size) at a random cell of every region.
  final clues = <Clue>[];
  for (var id = 0; id < regions.length; id++) {
    final cell = regions[id][rnd.nextInt(regions[id].length)];
    clues.add(Clue(
      row: cell ~/ size,
      col: cell % size,
      size: regions[id].length,
      region: id,
      style: styles[id],
    ));
  }

  return Level(
    number: number,
    kind: kind,
    size: size,
    blocked: <int>{},
    clues: clues,
    solution: owner,
  );
}

/// Splits the whole grid into connected regions of roughly [minS]..[maxS]
/// cells. Regions that end up too small are merged into a neighbour.
List<List<int>> _partition(int size, Random rnd, int minS, int maxS) {
  final n = size * size;
  final owner = List<int>.filled(n, kEmpty);
  final regions = <List<int>?>[];
  final order = List<int>.generate(n, (i) => i)..shuffle(rnd);

  for (final seed in order) {
    if (owner[seed] != kEmpty) continue;
    final id = regions.length;
    final target = minS + rnd.nextInt(maxS - minS + 1);
    final cells = <int>[seed];
    owner[seed] = id;
    while (cells.length < target) {
      final frontier = <int>[];
      for (final c in cells) {
        for (final nb in gridNeighbors(c, size)) {
          if (owner[nb] == kEmpty && !frontier.contains(nb)) frontier.add(nb);
        }
      }
      if (frontier.isEmpty) break;
      final pick = frontier[rnd.nextInt(frontier.length)];
      owner[pick] = id;
      cells.add(pick);
    }
    regions.add(cells);
  }

  while (true) {
    var small = -1;
    for (var i = 0; i < regions.length; i++) {
      final r = regions[i];
      if (r != null && r.length < minS) {
        small = i;
        break;
      }
    }
    if (small < 0) break;

    final smallCells = regions[small]!;
    var best = -1;
    for (final c in smallCells) {
      for (final nb in gridNeighbors(c, size)) {
        final o = owner[nb];
        if (o != small && (best < 0 || regions[o]!.length < regions[best]!.length)) {
          best = o;
        }
      }
    }
    if (best < 0) break;
    for (final c in smallCells) {
      owner[c] = best;
    }
    regions[best]!.addAll(smallCells);
    regions[small] = null;
  }

  return [
    for (final r in regions)
      if (r != null) r,
  ];
}

/// The generator's own safety check: the stored solution must satisfy
/// every rule, using the same validator as the game.
class PuzzleCheck {
  static bool isValid(Level level) => _check(level);
}

bool _check(Level level) {
  final sol = level.solution;
  if (sol.length != level.size * level.size) return false;
  if (sol.contains(kEmpty)) return false;
  final noOwners = List<int>.filled(sol.length, kEmpty);
  for (final clue in level.clues) {
    final members = <int>{
      for (var i = 0; i < sol.length; i++)
        if (sol[i] == clue.region) i,
    };
    final result = validateRegion(
      level: level,
      clue: clue,
      cells: members,
      owners: noOwners,
    );
    if (!result.isValid) return false;
  }
  return true;
}
