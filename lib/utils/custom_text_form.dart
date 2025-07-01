// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

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
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      initialValue: initial,
      readOnly: readOnly ?? false,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Color(0xFFf1b24b),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: Color(0xFFf1b24b),
              )
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                color: Color(0xFFf1b24b),
              )
            : null,
        filled: true,
        //! Check on the fill color
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: Color(0xFFf1b24b),
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: Color(0xFFf1b24b),
            width: 2.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
      style: TextStyle(
        color: chooseText == ChooseText.owes ? Colors.redAccent : Colors.white,
        fontWeight:
            chooseText == ChooseText.owes ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      ),
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      onFieldSubmitted: onSubmitted,
    );
  }
}
