import 'package:flutter/material.dart';
import 'package:scheldule/providers/login%20to%20sign%20up/change_page_state.dart';

class ChangePageProvider extends ChangeNotifier {
  ChangePageState _state = ChangePageState.initial();
  ChangePageState get state => _state;

  void changePage() async {
    if (_state.changePageStatus == ChangePageStatus.login) {
      _state = _state.copyWith(changePageStatus: ChangePageStatus.signup);
      notifyListeners();
    } else {
      _state = _state.copyWith(changePageStatus: ChangePageStatus.login);
      notifyListeners();
    }
  }
}
