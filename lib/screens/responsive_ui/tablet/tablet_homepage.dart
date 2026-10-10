import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/customer.dart';
import 'package:scheldule/screens/responsive_ui/tablet/income-expenses/income_expenses.dart';

import '../../../providers/drawer_nav/drawer_state.dart';
import '../../calendar/syncfusion_calendar.dart';
import '../tablet/appointments/appointments.dart';
import '../tablet/employee/employee.dart';
import '../tablet/settings/settings.dart';
import '../widgets/web_app_shell.dart';

class TabletHomepage extends StatelessWidget {
  const TabletHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebAppShell(
      layout: AppShellLayout.tablet,
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
