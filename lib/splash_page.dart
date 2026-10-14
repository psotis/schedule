import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'providers/auth/auth_provider.dart';
import 'providers/auth/auth_state.dart';
import 'screens/login/login_screen.dart';
import 'screens/responsive_ui/homepage.dart';
import 'screens/user_admin/user_admin_dashboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    initialization();
    super.initState();
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 1));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;
    switch (authState.authStatus) {
      case AuthStatus.authenticated:
        return authState.user?.role == 'user-admin'
            ? const UserAdminDashboard()
            : HomeLayoutScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
