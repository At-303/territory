import 'package:flutter/material.dart';

import '../storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shape_painter.dart';
import 'game_screen.dart';
import 'levels_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final ProgressStore store;

  void _play(BuildContext context, int level) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GameScreen(store: store, levelNumber: level),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Expanded(child: _Hero()),
                  PillButton(
                    label: 'Continue',
                    color: AppColors.blue,
                    height: 50,
                    onTap: () => _play(context, store.lastLevel),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'New',
                    color: AppColors.purple,
                    height: 50,
                    onTap: () => _play(context, store.nextLevel),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Levels',
                    color: AppColors.yellow,
                    height: 50,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LevelsScreen(store: store),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title plus the scattered decorative tiles.
class _Hero extends StatelessWidget {
  const _Hero();

  // x, y (fractions), style (-1 = empty tile), rotation in turns
  static const _tiles = <(double, double, int, double)>[
    (0.42, 0.04, 0, 0.04),
    (0.70, 0.02, -1, 0.0),
    (0.58, 0.14, 3, -0.03),
    (0.80, 0.16, -1, 0.0),
    (0.66, 0.30, 2, 0.02),
    (0.42, 0.26, -1, 0.0),
    (0.74, 0.46, 1, 0.0),
    (0.40, 0.52, 1, 0.03),
    (0.56, 0.48, 3, 0.0),
    (0.20, 0.60, -1, 0.0),
    (0.36, 0.68, 2, -0.02),
    (0.62, 0.72, -1, 0.0),
    (0.52, 0.86, 0, 0.03),
    (0.78, 0.84, -1, 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const tile = 30.0;
        return Stack(
          children: [
            for (final t in _tiles)
              Positioned(
                left: t.$1 * (c.maxWidth - tile),
                top: t.$2 * (c.maxHeight - tile),
                child: Transform.rotate(
                  angle: t.$4 * 6.2832,
                  child: Container(
                    width: tile,
                    height: tile,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.$3 < 0
                          ? Colors.transparent
                          : regionColors[t.$3 % regionColors.length],
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: AppColors.ink
                            .withValues(alpha: t.$3 < 0 ? 0.12 : 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: t.$3 < 0
                        ? null
                        : ShapeIcon(style: t.$3, size: tile * 0.4),
                  ),
                ),
              ),
            const Align(
              alignment: Alignment(-1, -0.35),
              child: Text(
                'Territory',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w400),
              ),
            ),
          ],
        );
      },
    );
  }
}
