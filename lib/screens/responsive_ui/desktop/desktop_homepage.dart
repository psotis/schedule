import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/screens/homepage/widgets/syncfusion_calendar.dart';
import 'package:scheldule/screens/responsive_ui/desktop/appointments/appointments.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/customer.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/employee.dart';
import 'package:scheldule/screens/responsive_ui/desktop/settings/settings.dart';

class DesktopHomepage extends StatefulWidget {
  final User? user;
  DesktopHomepage({super.key, this.user});

  @override
  State<DesktopHomepage> createState() => _DesktopHomepageState();
}

class _DesktopHomepageState extends State<DesktopHomepage> {
  int _selectedIndex = 0;
  User? user;

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  late final List _screens = [
    SyncFusionCalendar(user: user!),
    Appointments(user: user!),
    Customer(user: user!),
    Employee(user: user!),
    Settings(user: user!),
  ];

  @override
  Widget build(BuildContext context) {
    var checkTheme = context.watch<ThemeProvider>().state?.themeStatus;
    return Scaffold(
      body: Row(
        children: [
          _navigationRail(context, checkTheme),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  NavigationRail _navigationRail(
      BuildContext context, ThemeStatus? checkTheme) {
    return NavigationRail(
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: Text('Calendar'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: Text('Appointments'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Customer'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: Text('Employee'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      labelType: NavigationRailLabelType.all,
      elevation: 8,
      minWidth: 150,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (value) {
        setState(() {
          _selectedIndex = value;
        });
      },
      backgroundColor:
          checkTheme == ThemeStatus.dark ? Colors.grey[900] : Colors.grey[100],
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 40,
              child: Divider(
                thickness: 3,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logging out...')),
                );
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: Colors.blueAccent,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              height: 100,
              width: MediaQuery.of(context).size.width * .1,
            ),
            Divider(
              color: Colors.white,
              thickness: 2,
            )
          ],
        ),
      ),
      selectedIconTheme: IconThemeData(
        color: Colors.blueAccent,
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: checkTheme == ThemeStatus.dark
            ? Colors.grey[500]
            : Colors.grey[700],
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: checkTheme == ThemeStatus.dark
            ? Colors.grey[500]
            : Colors.grey[700],
      ),
    );
  }
}
