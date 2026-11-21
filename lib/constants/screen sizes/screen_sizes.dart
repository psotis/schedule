// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:material_ui/material_ui.dart';

class ScreenSize {
  static MediaQueryData? _mediaQueryData;
  static var screenWidth;
  static var screenHeight;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData?.size.width;
    screenHeight = _mediaQueryData?.size.height;
  }
}
