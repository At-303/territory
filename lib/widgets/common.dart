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
    this.fontSize = AppText.body,
    this.width,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: height,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular outlined icon button (back, eye, pause).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required Alignment position,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.ink;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 2.5),
        ),
        child: Icon(icon, size: 30, color: ink),
      ),
    );
  }
}

/// Card with a title and a column of buttons (pause + solved dialogs).
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    required this.buttons,
    required double fontSize,
  });

  final String title;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: p.dialog,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.ink, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: AppText.body)),
            const SizedBox(height: 20),
            for (final b in buttons) ...[
              b,
              if (b != buttons.last) const SizedBox(height: 25),
            ],
          ],
        ),
      ),
    );
  }
}