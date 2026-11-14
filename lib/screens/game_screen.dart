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
      case CheckResult.wrong:
        _snack(game.message);
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
        fontSize: AppText.body,
        buttons: [
          PillButton(
            label: 'Resume',
            color: AppColors.green,
            height: 36,
            width: 287,
            fontSize: AppText.body,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          PillButton(
            label: 'Restart',
            color: AppColors.yellow,
            height: 36,
            width: 287,
            fontSize: AppText.body,
            onTap: () {
              game.restart();
              Navigator.of(dialogContext).pop();
            },
          ),
          PillButton(
            label: 'Exit',
            color: AppColors.coral,
            height: 36,
            width: 287,
            fontSize: AppText.body,
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
              label: 'Next',
              color: AppColors.green,
              height: 36,
              width: 287,
              fontSize: AppText.body,
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
            label: 'Home',
            color: AppColors.yellow,
            height: 36,
            width: 287,
            fontSize: AppText.body,
            onTap: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
        fontSize: AppText.body,
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
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back,
                          position: Alignment.centerLeft,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  game.level.kind
                                      .title, // "Easy", "Medium", "Hard", "Expert"
                                  style: const TextStyle(
                                    fontSize: AppText.heading,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoundIconButton(
                          icon: game.showSymbols
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onTap: game.toggleSymbols,
                          position: Alignment.centerLeft,
                        ),
                        const SizedBox(width: 24),
                       RoundIconButton(
  icon: widget.store.darkMode
      ? Icons.light_mode_outlined
      : Icons.dark_mode_outlined,
  onTap: widget.store.toggleDark,
  position: Alignment.center,
),
                        const SizedBox(width: 24),
                        RoundIconButton(
                          icon: Icons.pause,
                          position: Alignment.centerRight,
                          onTap: _showPause,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: AppText.body),
                        const SizedBox(width: 4),
                        Text(
                          _time(game.seconds),
                          style: const TextStyle(
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Board(game: game),
                    const SizedBox(height: 28),
                    Visibility(
                      visible: game.isFull,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: SizedBox(
                        width: 150,
                        child: PillButton(
                          label: 'Check',
                          color: AppColors.green,
                          onTap: _check,
                          width: 180,
                        ),
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
