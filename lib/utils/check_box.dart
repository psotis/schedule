import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color checkColor;
  final TextStyle? labelStyle;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.size = 24.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.checkColor = Colors.white,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: value ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
            child: value
                ? Icon(Icons.check, size: size * 0.6, color: checkColor)
                : null,
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
