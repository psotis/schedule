import 'dart:async';
import 'package:flutter/cupertino.dart';

import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.unknown();
  AuthState get state => _state;

  final AuthRepository authRepository;
  late final StreamSubscription<AppUser?> _subscription;
  AuthProvider({
    required this.authRepository,
  }) {
    _subscription = authRepository.user.listen(update);
    update(authRepository.currentUser);
  }

  void update(AppUser? user) {
    _state = AuthState(
      authStatus:
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
    );
    notifyListeners();
  }

  Future<void> signout() async {
    await authRepository.signout();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
