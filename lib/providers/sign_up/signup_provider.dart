import 'package:flutter/material.dart';

import '../../models/custom_errors.dart';
import '../../repositories/auth_repository.dart';
import 'signup_state.dart';

class SignupProvider with ChangeNotifier {
  SignupState _state = SignupState.initial();
  SignupState get state => _state;

  final AuthRepository authRepository;
  SignupProvider({
    required this.authRepository,
  });

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String storeType,
  }) async {
    _state = _state.copyWith(signinStatus: SignupStatus.submitting);
    notifyListeners();
    try {
      await authRepository.signup(
        name: name,
        email: email,
        password: password,
        storeType: storeType,
      );
      _state = _state.copyWith(signinStatus: SignupStatus.success);
      notifyListeners();
    } on CustomError catch (e) {
      _state = _state.copyWith(signinStatus: SignupStatus.error, error: e);
      notifyListeners();
      rethrow;
    }
  }
}
