import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/desktop/desktop_homepage.dart';
import 'package:scheldule/screens/responsive_ui/mobile/mobile_homepage.dart';
import 'package:scheldule/screens/responsive_ui/responsive_layout.dart';
import 'package:scheldule/screens/responsive_ui/tablet/tablet_homepage.dart';

class HomeLayoutScreen extends StatelessWidget {
  HomeLayoutScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ResponsiveLayout(
        mobile: MobileHomepage(user: user),
        tablet: TabletHomepage(user: user),
        desktop: DesktopHomepage(user: user),
      ),
    );
  }
}
