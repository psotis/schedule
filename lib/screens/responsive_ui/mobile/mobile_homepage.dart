import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_provider.dart';
import 'package:scheldule/screens/homepage/widgets/syncfusion_calendar.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/appointments.dart';
import 'package:scheldule/screens/responsive_ui/mobile/customer/customer.dart';
import 'package:scheldule/screens/responsive_ui/mobile/employee/employee.dart';
import 'package:scheldule/screens/responsive_ui/mobile/settings/settings.dart';
import 'package:scheldule/utils/nav_drawer.dart';

import '../../../providers/drawer_nav/drawer_state.dart';

class MobileHomepage extends StatelessWidget {
  final User? user;
  MobileHomepage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawerProvider>(builder: (context, state, child) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.1, 0.5, 0.7, 0.9],
            colors: [
              Color(0xFF005448),
              Color(0xFF007a6b),
              Color(0xFF00a190),
              Color(0xFF00c9b7),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(state.state.title)),
          drawer: DrawerNavigation(),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: pages(state),
          ),
        ),
      );
    });
  }

  Widget pages(DrawerProvider provider) {
    if (provider.state.drawerStatus == DrawerStatus.customer) {
      return Customer(user: user!);
    }
    if (provider.state.drawerStatus == DrawerStatus.employee) {
      return Employee(user: user!);
    }
    if (provider.state.drawerStatus == DrawerStatus.appointments) {
      return Appointments(user: user!);
    }
    if (provider.state.drawerStatus == DrawerStatus.settings) {
      return Settings(user: user!);
    }
    return SyncFusionCalendar(user: user!);
  }
}
