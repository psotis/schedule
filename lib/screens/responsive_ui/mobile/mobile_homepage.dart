import 'package:flutter/material.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/appointments.dart';
import 'package:scheldule/screens/responsive_ui/mobile/customer/customer.dart';
import 'package:scheldule/screens/responsive_ui/mobile/employee/employee.dart';
import 'package:scheldule/screens/responsive_ui/mobile/income-expenses/income_expenses.dart';
import 'package:scheldule/screens/responsive_ui/mobile/settings/settings.dart';
import 'package:scheldule/screens/responsive_ui/widgets/web_app_shell.dart';

import '../../../providers/drawer_nav/drawer_state.dart';

class MobileHomepage extends StatelessWidget {
  const MobileHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebAppShell(
      layout: AppShellLayout.mobile,
      pageBuilder: (status, canManage) => _pageFor(status, canManage),
    );
  }

  Widget _pageFor(DrawerStatus status, bool canManage) {
    switch (status) {
      case DrawerStatus.appointments:
        return const Appointments();
      case DrawerStatus.customer:
        return const Customer();
      case DrawerStatus.employee:
        return canManage ? const Employee() : const SyncFusionCalendar();
      case DrawerStatus.incexp:
        return canManage ? const IncomeExpenses() : const SyncFusionCalendar();
      case DrawerStatus.settings:
        return canManage ? const Settings() : const SyncFusionCalendar();
      case DrawerStatus.calendar:
        return const SyncFusionCalendar();
    }
  }
}
