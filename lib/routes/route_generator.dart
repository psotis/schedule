import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/homepage.dart';

import '../screens/login/login_screen.dart';
import '../screens/user_admin/user_admin_dashboard.dart';
import '../splash_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => SplashPage());
      case '/login':
        return MaterialPageRoute(builder: (context) => LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (context) => HomeLayoutScreen());
      case '/user-admin':
        return MaterialPageRoute(
          builder: (context) => const UserAdminDashboard(),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Error',
            ),
            centerTitle: true,
          ),
          body: const Center(
            child: Text('Page not found'),
          ),
        );
      },
    );
  }
}
