import 'package:flutter/material.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';
import 'package:scheldule/screens/responsive_ui/desktop/desktop_homepage.dart';
import 'package:scheldule/screens/responsive_ui/mobile/mobile_homepage.dart';
import 'package:scheldule/screens/responsive_ui/responsive_layout.dart';
import 'package:scheldule/screens/responsive_ui/tablet/tablet_homepage.dart';

class HomeLayoutScreen extends StatelessWidget {
  HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return PopScope(
      canPop: false,
      child: ResponsiveLayout(
        mobile: const MobileHomepage(),
        tablet: const TabletHomepage(),
        desktop: const DesktopHomepage(),
      ),
    );
  }
}
