import 'package:material_ui/material_ui.dart';

import '../splash_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (Uri.parse(settings.name ?? '/').path) {
      case '/':
      case '/billing':
      case '/billing/success':
      case '/billing/failure':
      case '/login':
      case '/home':
      case '/user-admin':
        return MaterialPageRoute(builder: (context) => const SplashPage());

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
              'Error'),
            centerTitle: true),
          body: const Center(
            child: Text('Page not found')),
        );
      },
    );
  }
}
