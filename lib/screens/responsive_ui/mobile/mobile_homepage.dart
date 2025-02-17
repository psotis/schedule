import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_provider.dart';
import 'package:scheldule/screens/homepage/widgets/syncfusion_calendar.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/appointments_homepage.dart';
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
      return Scaffold(
        appBar: AppBar(title: Text(state.state.title)),
        drawer: DrawerNavigation(),
        body: pages(state),
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
