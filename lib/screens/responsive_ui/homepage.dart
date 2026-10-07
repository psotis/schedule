import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/desktop/desktop_homepage.dart';
import 'package:scheldule/screens/responsive_ui/mobile/mobile_homepage.dart';
import 'package:scheldule/screens/responsive_ui/responsive_layout.dart';
import 'package:scheldule/screens/responsive_ui/tablet/tablet_homepage.dart';

class HomeLayoutScreen extends StatelessWidget {
  HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ResponsiveLayout(
        mobile: MobileHomepage(),
        tablet: TabletHomepage(),
        desktop: DesktopHomepage(),
      ),
    );
  }
}
