import 'package:flutter/material.dart';
import 'package:scheldule/providers/drawer_nav/drawer_state.dart';

class DrawerProvider extends ChangeNotifier {
  DrawerState _state = DrawerState.initial();
  DrawerState get state => _state;

  void changePage(DrawerStatus drawerStatus, String title) {
    if (state.drawerStatus != drawerStatus) {
      _state = _state.copyWith(drawerStatus: drawerStatus, title: title);
      notifyListeners();
    }
  }
}
