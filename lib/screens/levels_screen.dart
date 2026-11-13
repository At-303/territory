import 'package:flutter/material.dart';

import '../game/level.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'game_screen.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key, required this.store});

  final ProgressStore store;

  static const _rowColors = [
    AppColors.green,
    AppColors.yellow,
    AppColors.coral,
    AppColors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Levels',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${store.completed.length}/$kLevelCount',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: kLevelCount,
                        itemBuilder: (context, i) {
                          final n = i + 1;
                          return _LevelTile(
                            number: n,
                            color: _rowColors[(i ~/ 4) % _rowColors.length],
                            done: store.completed.contains(n),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GameScreen(
                                  store: store,
                                  levelNumber: n,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.color,
    required this.done,
    required this.onTap,
  });

  final int number;
  final Color color;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.6)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('$number', style: const TextStyle(fontSize: 26)),
              if (done)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.check, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
