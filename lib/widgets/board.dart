import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/level.dart';
import '../theme.dart';
import 'shape_painter.dart';

/// The puzzle grid. Drag from a number (or a painted cell) to paint its
/// region, tap a painted cell to erase it.
class Board extends StatelessWidget {
  const Board({super.key, required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    final size = game.level.size;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final cellSize = side / size;

        int indexAt(Offset p) {
          final r = (p.dy / cellSize).floor().clamp(0, size - 1);
          final c = (p.dx / cellSize).floor().clamp(0, size - 1);
          return r * size + c;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => game.beginDrag(indexAt(d.localPosition)),
          onPanUpdate: (d) => game.dragTo(indexAt(d.localPosition)),
          onPanEnd: (_) => game.endDrag(),
          onPanCancel: game.endDrag,
          onTapUp: (d) => game.tap(indexAt(d.localPosition)),
          child: SizedBox(
            width: side,
            height: side,
            child: Column(
              children: [
                for (var r = 0; r < size; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < size; c++)
                          Expanded(
                              child: _Cell(game: game, index: r * size + c)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.game, required this.index});

  final GameController game;
  final int index;

  @override
  Widget build(BuildContext context) {
    final value = game.cells[index];
    final clue = game.clueAt[index];
    final selected = game.selection.contains(index);
    final error = game.errorCells.contains(index);

    // Priority: blocked, error (red), confirmed region, numbered cell,
    // selection (lighter tint of the region colour), empty.
    Color fill;
    if (value == kBlocked) {
      fill = Colors.black;
    } else if (error) {
      fill = AppColors.error;
    } else if (value >= 0) {
      fill = regionColors[_styleOf(value)];
    } else if (clue != null) {
      fill = regionColors[clue.style];
    } else if (selected) {
      fill = Color.lerp(
        context.palette.cell,
        regionColors[game.activeStyle],
        0.55,
      )!;
    } else {
      fill = context.palette.cell;
    }

    Widget? child;
    if (clue != null) {
      child = Text(
        '${clue.size}',
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
      );
    } else if (value >= 0 && !error && game.showSymbols) {
      child = LayoutBuilder(
        builder: (context, c) => ShapeIcon(
          style: _styleOf(value),
          size: c.maxWidth * 0.42,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value == kBlocked
                ? Colors.black
                : (value >= 0 || clue != null || error
                    ? AppColors.ink.withValues(alpha: 0.55)
                    : context.palette.ink
                        .withValues(alpha: selected ? 0.9 : 0.35)),
          ),
        ),
        child: child,
      ),
    );
  }

  int _styleOf(int region) => game.level.clues[region].style;
}
