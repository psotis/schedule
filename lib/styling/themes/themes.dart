import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Themes {
  ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      // primary: Color.fromARGB(255, 128, 65, 6),
      // secondary: Color.fromARGB(255, 128, 65, 6),
      // background: Colors.teal.shade500,
    ),
    // scaffoldBackgroundColor: Colors.brown,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 228, 251, 252),
    ),
  ).copyWith(
    textTheme: GoogleFonts.aBeeZeeTextTheme(Typography.whiteCupertino),
  );

  ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
    ),
  ).copyWith(
    textTheme: GoogleFonts.aBeeZeeTextTheme(Typography.whiteCupertino),
  );
}