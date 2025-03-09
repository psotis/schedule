import 'package:flutter/material.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/styling/themes/dark_theme.dart';
import 'package:scheldule/styling/themes/light_theme.dart';

import '../../main.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeState? _state = ThemeState.initial();
  ThemeState? get state => _state;

  void changeTheme() async {
    if (state?.themeStatus == ThemeStatus.dark) {
      _state = _state?.copyWith(
          themeData: lightTheme, themeStatus: ThemeStatus.light);
      prefs?.setString('theme', 'light');
      notifyListeners();
    } else {
      _state =
          _state?.copyWith(themeData: darkTheme, themeStatus: ThemeStatus.dark);
      prefs?.setString('theme', 'dark');
      notifyListeners();
    }
  }
}
