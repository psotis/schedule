import 'package:flutter/foundation.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_state.dart';

class ToggleScreenProvider with ChangeNotifier {
  ToggleState? _toggleState = ToggleState.initial();
  ToggleState? get toggleState => _toggleState;

  void showInitialScreen() {
    _toggleState = _toggleState!.copyWith(
        customer: AppointMent.initial(), toggleStatus: ToggleStatus.no);
    notifyListeners();
  }

  void showScreen(AppointMent customer) async {
    _toggleState = _toggleState!.copyWith(
        customer: AppointMent.initial(), toggleStatus: ToggleStatus.no);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 100));

    _toggleState = _toggleState!
        .copyWith(customer: customer, toggleStatus: ToggleStatus.yes);
    notifyListeners();
  }
}
