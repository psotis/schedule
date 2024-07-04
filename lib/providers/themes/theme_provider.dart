import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../models/theme_model.dart';

class ThemeProvider extends ChangeNotifier {
  bool loading = false;
  ThemeModel? _state = ThemeModel.initial();
  ThemeModel? get state => _state;

  void changeTheme(bool checked) async {
    loading = true;
    prefs = await SharedPreferences.getInstance();
    if (_state?.isChecked == checked) {
      _state = _state?.copyWith(themeStatus: ThemeStatus.dark);
      prefs?.setBool('isDarkTheme', false);
    } else {
      _state = _state?.copyWith(themeStatus: ThemeStatus.light);
      prefs?.setBool('isDarkTheme', true);
    }
    await Future.delayed(Duration(milliseconds: 500));
    loading = false;

    notifyListeners();
  }
}
