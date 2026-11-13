import 'package:flutter/material.dart';

import '../theme.dart';

/// Flat rounded button used on every screen (Continue, Check, Resume ...).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.height = 46,
    this.fontSize = 14,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// Circular outlined icon button (back, eye, pause).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
    );
  }
}

/// Card with a title and a column of buttons (pause + solved dialogs).
class GameDialog extends StatelessWidget {
  const GameDialog({super.key, required this.title, required this.buttons});

  final String title;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.dialog,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.ink, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            for (final b in buttons) ...[
              b,
              if (b != buttons.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
