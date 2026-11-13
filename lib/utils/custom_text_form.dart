// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:material_ui/material_ui.dart';

enum ChooseText { owes }

class CustomTextForm extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final void Function(String?)? onSaved;
  final void Function(String?)? onSubmitted;
  final bool obscureText;
  final TextEditingController? controller;
  final String? initial;
  final ChooseText? chooseText;
  final bool? readOnly;

  const CustomTextForm({
    super.key,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onSubmitted,
    this.obscureText = false,
    this.controller,
    this.initial,
    this.chooseText,
    this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isReadOnly = readOnly ?? false;
    final radius = BorderRadius.circular(14);
    final iconColor = WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.error)) return colors.error;
      if (states.contains(WidgetState.focused) && !isReadOnly) {
        return colors.primary;
      }
      return colors.onSurfaceVariant;
    });

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      initialValue: initial,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.error)
                ? colors.error
                : isReadOnly
                    ? colors.onSurfaceVariant
                    : colors.primary,
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w600,
          );
        }),
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withAlpha(170),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: iconColor,
        suffixIconColor: iconColor,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
        filled: true,
        fillColor: isReadOnly
            ? colors.surfaceContainerLow
            : theme.inputDecorationTheme.fillColor ?? colors.surface,
        hoverColor: colors.primary.withAlpha(dark ? 14 : 7),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: colors.outlineVariant.withAlpha(dark ? 160 : 210),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: isReadOnly ? colors.outlineVariant : colors.primary,
            width: isReadOnly ? 1 : 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        errorMaxLines: 3,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: radius),
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: chooseText == ChooseText.owes ? colors.error : colors.onSurface,
        fontWeight:
            chooseText == ChooseText.owes ? FontWeight.w600 : FontWeight.w400,
        fontSize: 15,
        height: 1.4,
      ),
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      onFieldSubmitted: onSubmitted,
    );
  }
}
