import 'package:flutter/material.dart';
import '../game/level.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/shape_painter.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final ProgressStore store;

    void _play(BuildContext context, int level) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GameScreen(store: store, levelNumber: level),
    ));
  }

  Future<void> _newGame(BuildContext context) async {
    const colors = [
      AppColors.green,
      AppColors.yellow,
      AppColors.coral,
      AppColors.blue,
    ];
    final picked = await showDialog<Difficulty>(
      context: context,
      builder: (dialogContext) => GameDialog(
        title: 'Choose difficulty',
        buttons: [
          for (final d in Difficulty.values)
            PillButton(
              label: '${d.title}  ${d.gridSize}x${d.gridSize}',
              color: colors[d.index],
              width: 220,
              onTap: () => Navigator.of(dialogContext).pop(d),
            ),
        ], fontSize: AppText.body,
      ),
    );
    if (picked != null && context.mounted) {
      _play(context, store.nextLevelIn(picked));
    }
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
                  const SizedBox(height: 56),
                  PillButton(
                    label: 'Continue',
                    color: AppColors.blue,
                    height: 80,
                    onTap: () => _play(context, store.lastLevel), width: 285, 
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'New',
                    color: AppColors.purple,
                    height: 80,                 
                   onTap: () => _newGame(context), width: 285,
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

  // One letter per tile:
  //   .  no tile            _  empty tile
  //   s  blue square        c  yellow circle     t  purple triangle
  //   h  coral heart        x  green sparkle
  //   UPPERCASE = same colour, no symbol (S C T H X)
  static const _pattern = [
    '..s_.',
    '.._H_',
    '.__T_',
    'Ch_c_',
    '__t_.',
    '.S__.',
    '.._..',
  ];

  static const _tilt = -0.33; // radians, about -19 degrees

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.12; // tile size
    final gap = w * 0.024; // space between tiles

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tile grid: centred 75% across, a bit above the middle,
        // and allowed to run off the right edge of the screen.
        OverflowBox(
          alignment: const Alignment(4, 0.5),
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.rotate(
            angle: _tilt,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in _pattern)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final ch in row.split(''))
                          Padding(
                            padding: EdgeInsets.only(right: gap),
                           child: _tile(context, ch, size),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment(-1, -0.35),
          child: Text(
            'Territory',
            style: TextStyle(
              fontSize: AppText.display,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
 Widget _tile(BuildContext context, String ch, double size) {
    if (ch == '.') return SizedBox(width: size, height: size);
    final style = 'scthx'.indexOf(ch.toLowerCase()); // -1 for '_'
    final empty = style < 0;
    final symbol = !empty && ch == ch.toLowerCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: empty ? Colors.transparent : regionColors[style],
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: (empty ? context.palette.ink : AppColors.ink)
              .withValues(alpha: empty ? 0.2 : 0.35),
          width: 0.8,
        ),
      ),
      child: symbol ? ShapeIcon(style: style, size: size * 0.42) : null,
    );
  }
}