import 'package:flutter/material.dart';

class SendButton extends StatelessWidget {
  final IconData? icon;
  final void Function()? onPressed;
  final Color? textColor;
  final Color? iconColor;
  final Color? pressedColor;
  final Color? hoveredColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String text;
  const SendButton({
    super.key,
    this.icon,
    required this.onPressed,
    this.textColor,
    this.iconColor,
    this.pressedColor,
    this.hoveredColor,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => onPressed?.call(),
      icon: Icon(icon, color: iconColor, size: 22),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6, // Depth effect
        shadowColor: Colors.black.withAlpha(40),
        backgroundColor: backgroundColor ?? Colors.blue.shade700,
        foregroundColor: foregroundColor ?? Colors.white,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return pressedColor ?? Colors.blue.shade900;
            } else if (states.contains(WidgetState.hovered)) {
              return hoveredColor ?? Colors.blue.shade800;
            }
            return backgroundColor ?? Colors.blue.shade700;
          },
        ),
      ),
    );
  }
}
