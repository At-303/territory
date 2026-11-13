import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/level.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/board.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.store, required this.levelNumber});

  final ProgressStore store;
  final int levelNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController game;

  @override
  void initState() {
    super.initState();
    game = GameController(generateLevel(widget.levelNumber))..start();
    widget.store.setLast(widget.levelNumber);
  }

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  String _time(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _check() async {
    switch (game.check()) {
      case CheckResult.incomplete:
        _snack('Some cells are still empty');
      case CheckResult.wrong:
        _snack('Not quite - check your regions');
      case CheckResult.solved:
        await widget.store.markCompleted(widget.levelNumber);
        if (!mounted) return;
        await _showSolved();
    }
  }

  Future<void> _showPause() async {
    game.pause();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameDialog(
        title: 'Game paused',
        buttons: [
          PillButton(
            label: 'Resume',
            color: AppColors.green,
            height: 36,
            fontSize: 12,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          PillButton(
            label: 'Restart',
            color: AppColors.yellow,
            height: 36,
            fontSize: 12,
            onTap: () {
              game.restart();
              Navigator.of(dialogContext).pop();
            },
          ),
          PillButton(
            label: 'Exit',
            color: AppColors.coral,
            height: 36,
            fontSize: 12,
            onTap: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    if (mounted) game.resume();
  }

  Future<void> _showSolved() async {
    final hasNext = widget.levelNumber < kLevelCount;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameDialog(
        title: 'Solved in ${_time(game.seconds)}',
        buttons: [
          if (hasNext)
            PillButton(
              label: 'Next level',
              color: AppColors.green,
              height: 36,
              fontSize: 12,
              onTap: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => GameScreen(
                    store: widget.store,
                    levelNumber: widget.levelNumber + 1,
                  ),
                ));
              },
            ),
          PillButton(
            label: 'Levels',
            color: AppColors.yellow,
            height: 36,
            fontSize: 12,
            onTap: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListenableBuilder(
              listenable: game,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              Text(
                                game.level.difficulty,
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                'Level ${widget.levelNumber}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RoundIconButton(
                          icon: game.showSymbols
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onTap: game.toggleSymbols,
                        ),
                        const SizedBox(width: 10),
                        RoundIconButton(
                          icon: Icons.pause,
                          onTap: _showPause,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _time(game.seconds),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Board(game: game),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 150,
                      child: PillButton(
                        label: 'Check',
                        color: AppColors.green,
                        onTap: _check,
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
