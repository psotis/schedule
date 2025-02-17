import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[850],
  ),
).copyWith(
  textTheme: GoogleFonts.aBeeZeeTextTheme(Typography.whiteCupertino),
);
