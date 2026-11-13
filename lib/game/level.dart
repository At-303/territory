import 'dart:math';

const int kEmpty = -1;
const int kBlocked = -2;
const int kLevelCount = 24;

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
  final int region;

  /// 0..4 -> colour + symbol (square, circle, triangle, heart, sparkle).
  final int style;
}

class Level {
  Level({
    required this.number,
    required this.size,
    required this.blocked,
    required this.clues,
    required this.solution,
  });

  final int number;
  final int size;
  final Set<int> blocked;
  final List<Clue> clues;

  /// One valid solution: kBlocked or a region id per cell.
  final List<int> solution;

  String get difficulty => number <= 12
      ? 'easy'
      : number <= 18
          ? 'medium'
          : 'hard';

  int index(int r, int c) => r * size + c;
}

/// Builds a level deterministically from its number, so the puzzle is
/// always solvable (it is generated from a solution).
Level generateLevel(int number, {int size = 7}) {
  final rnd = Random(number * 7919 + 17);
  final n = size * size;

  // 1. A connected blob of blocked (black) cells.
  final blockedTarget = min(4 + number ~/ 4, 10);
  final blocked = <int>{rnd.nextInt(n)};
  while (blocked.length < blockedTarget) {
    final frontier = <int>{
      for (final b in blocked) ...gridNeighbors(b, size),
    }..removeAll(blocked);
    blocked.add(frontier.elementAt(rnd.nextInt(frontier.length)));
  }

  // 2. Partition the remaining cells into connected regions.
  final region = List<int>.filled(n, kEmpty);
  for (final b in blocked) {
    region[b] = kBlocked;
  }
  final members = <List<int>>[];
  final order = [
    for (var i = 0; i < n; i++)
      if (region[i] == kEmpty) i,
  ]..shuffle(rnd);

  for (final seed in order) {
    if (region[seed] != kEmpty) continue;
    final id = members.length;
    final target = 2 + rnd.nextInt(5) + (number >= 13 ? 1 : 0);
    final cells = <int>[seed];
    region[seed] = id;
    while (cells.length < target) {
      final frontier = <int>{
        for (final c in cells)
          for (final nb in gridNeighbors(c, size))
            if (region[nb] == kEmpty) nb,
      };
      if (frontier.isEmpty) break;
      final pick = frontier.elementAt(rnd.nextInt(frontier.length));
      region[pick] = id;
      cells.add(pick);
    }
    members.add(cells);
  }

  // 3. Give neighbouring regions different styles where possible.
  final styles = List<int>.filled(members.length, -1);
  for (var id = 0; id < members.length; id++) {
    final used = <int>{};
    for (final cell in members[id]) {
      for (final nb in gridNeighbors(cell, size)) {
        final other = region[nb];
        if (other >= 0 && other != id && styles[other] >= 0) {
          used.add(styles[other]);
        }
      }
    }
    var s = 0;
    while (s < 5 && used.contains(s)) {
      s++;
    }
    styles[id] = s < 5 ? s : id % 5;
  }

  // 4. One clue (the region size) at a random cell of every region.
  final clues = <Clue>[];
  for (var id = 0; id < members.length; id++) {
    final cell = members[id][rnd.nextInt(members[id].length)];
    clues.add(Clue(
      row: cell ~/ size,
      col: cell % size,
      size: members[id].length,
      region: id,
      style: styles[id],
    ));
  }

  return Level(
    number: number,
    size: size,
    blocked: blocked,
    clues: clues,
    solution: region,
  );
}
