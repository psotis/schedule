import 'package:flutter/material.dart';

import '../../models/custom_errors.dart';
import '../../repositories/auth_repository.dart';
import 'login_state.dart';

class SigninProvider with ChangeNotifier {
  SigninState _state = SigninState.initial();
  SigninState get state => _state;

  final AuthRepository authRepository;
  SigninProvider({
    required this.authRepository,
  });

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(signinStatus: SigninStatus.submitting);
    notifyListeners();
    try {
      await authRepository.signin(email: email, password: password);
      _state = _state.copyWith(signinStatus: SigninStatus.success);
      notifyListeners();
    } on CustomError catch (e) {
      _state = _state.copyWith(signinStatus: SigninStatus.error, error: e);
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }
}
