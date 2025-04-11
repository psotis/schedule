import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
// import 'package:scheldule/screens/gemini%20chat/gemini_chat.dart';
import 'package:scheldule/screens/responsive_ui/desktop/appointments/appointments.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/customer.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/employee.dart';
import 'package:scheldule/screens/responsive_ui/desktop/settings/settings.dart';

import '../../../constants/logos/photos_gifs.dart';

class DesktopHomepage extends StatefulWidget {
  final User? user;
  DesktopHomepage({super.key, this.user});

  @override
  State<DesktopHomepage> createState() => _DesktopHomepageState();
}

class _DesktopHomepageState extends State<DesktopHomepage> {
  int _selectedIndex = 0;
  User? user;

  bool isChatOpen = false;

  void toggleChat() {
    setState(() {
      isChatOpen = !isChatOpen;
    });
  }

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  Future logout() async {
    await FirebaseAuth.instance.signOut();
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
      body: Container(
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
        child: Row(
          children: [
            // Navigation Rail
            _navigationRail(context, checkTheme),

            // Main Content
            Expanded(
              child: Stack(
                children: [
                  _screens[_selectedIndex],
                  // if (isChatOpen)
                  //   Positioned(
                  //     right: 16,
                  //     bottom: 16,
                  //     child:
                  //         GeminiChat(onClose: toggleChat, user: widget.user!),
                  //   ),
                  // if (!isChatOpen)
                  //   Positioned(
                  //     right: 16,
                  //     bottom: 16,
                  //     child: FloatingActionButton(
                  //       onPressed: toggleChat,
                  //       child: Icon(Icons.chat),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ],
        ),
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
                logout();
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                  image: DecorationImage(
                      image: AssetImage(
                    Media.logoGif,
                  ))),
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
