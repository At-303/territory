import 'level.dart';

enum RegionError {
  missingClue,
  multipleClues,
  wrongSize,
  disconnected,
  overlap,
}

class RegionValidation {
  const RegionValidation.ok()
      : error = null,
        message = '';
  const RegionValidation.fail(RegionError this.error, this.message);

  final RegionError? error;
  final String message;

  bool get isValid => error == null;
}

/// True if [cells] form one group joined horizontally or vertically
/// (diagonals do not count).
bool isConnected(Iterable<int> cells, int size) {
  final set = cells.toSet();
  if (set.isEmpty) return false;
  final start = set.first;
  final seen = <int>{start};
  final stack = <int>[start];
  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    for (final nb in gridNeighbors(cur, size)) {
      if (set.contains(nb) && seen.add(nb)) stack.add(nb);
    }
  }
  return seen.length == set.length;
}

/// The single place where a region is judged. Used when the player
/// confirms a region, in the final check, and by the generator.
///
/// [owners] holds the confirmed region id of every cell (or [kEmpty]).
/// Cells owned by the same region as [clue] do not count as overlap.
RegionValidation validateRegion({
  required Level level,
  required Clue clue,
  required Set<int> cells,
  required List<int> owners,
}) {
  final clueCell = level.clueIndex(clue);

  // 1. Must contain the region's own numbered cell.
  if (!cells.contains(clueCell)) {
    return RegionValidation.fail(
      RegionError.missingClue,
      'The region must include its numbered cell (${clue.size}).',
    );
  }

  // 2. Exactly one numbered cell.
  final numbers = cells.where(level.clueByCell.containsKey).length;
  if (numbers != 1) {
    return RegionValidation.fail(
      RegionError.multipleClues,
      'A region can contain only one number, but this one has $numbers.',
    );
  }

  // 3. Cell count matches the number.
  if (cells.length != clue.size) {
    return RegionValidation.fail(
      RegionError.wrongSize,
      'This region needs ${clue.size} cells but has ${cells.length}.',
    );
  }

  // 4. Connected horizontally or vertically.
  if (!isConnected(cells, level.size)) {
    return const RegionValidation.fail(
      RegionError.disconnected,
      'All cells in a region must touch horizontally or vertically.',
    );
  }

  // 5. No cell may belong to another confirmed region.
  for (final c in cells) {
    final owner = owners[c];
    if (owner >= 0 && owner != clue.region) {
      return const RegionValidation.fail(
        RegionError.overlap,
        'Some selected cells already belong to another region.',
      );
    }
  }

  return const RegionValidation.ok();
}
