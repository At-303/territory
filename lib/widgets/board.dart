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
                          Expanded(child: _Cell(game: game, index: r * size + c)),
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

    Color fill;
    if (value == kBlocked) {
      fill = Colors.black;
    } else if (value == kEmpty) {
      fill = Colors.white;
    } else {
      final style = clue?.style ?? _styleOf(value);
      fill = regionColors[style];
    }

    Widget? child;
    if (clue != null) {
      child = Text(
        '${clue.size}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
    } else if (value >= 0 && game.showSymbols) {
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
                : AppColors.ink.withValues(alpha: 0.55),
            width: 0.8,
          ),
        ),
        child: child,
      ),
    );
  }

  int _styleOf(int region) =>
      game.level.clues.firstWhere((c) => c.region == region).style;
}
