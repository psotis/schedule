// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_provider.dart';

import '../providers/drawer_nav/drawer_state.dart';

class DrawerNavigation extends StatefulWidget {
  DrawerNavigation({super.key});

  @override
  State<DrawerNavigation> createState() => _DrawerNavigationState();
}

class _DrawerNavigationState extends State<DrawerNavigation> {
  final List<Nav> nav = [
    Nav(
      drawerStatus: DrawerStatus.calendar,
      title: 'Calendar',
      icon: Icons.calendar_month,
    ),
    Nav(
      drawerStatus: DrawerStatus.appointments,
      title: 'Appointments',
      icon: Icons.calendar_today,
    ),
    Nav(
      drawerStatus: DrawerStatus.customer,
      title: 'Customer',
      icon: Icons.people,
    ),
    Nav(
      drawerStatus: DrawerStatus.employee,
      title: 'Employee',
      icon: Icons.work,
    ),
    Nav(
      drawerStatus: DrawerStatus.settings,
      title: 'Settings',
      icon: Icons.settings,
    ),
  ];

  Future logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(child: Container(color: Colors.teal)),
          Consumer<DrawerProvider>(builder: (context, state, child) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: nav.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: Text(
                      nav[index].title,
                      style: TextStyle(
                        color:
                            state.state.drawerStatus == nav[index].drawerStatus
                                ? Colors.blue
                                : null,
                      ),
                    ),
                    leading: Icon(
                      nav[index].icon,
                      color: state.state.drawerStatus == nav[index].drawerStatus
                          ? Colors.blue
                          : null,
                    ),
                    onTap: () {
                      context.read<DrawerProvider>().changePage(
                            nav[index].drawerStatus,
                            nav[index].title,
                          );
                      Navigator.pop(context);
                    });
              },
            );
          }),
          Spacer(),
          Container(
            padding: EdgeInsets.only(bottom: 20),
            child: ListTile(
              title: Text('Log out'),
              leading: Icon(Icons.logout),
              onTap: logout,
            ),
          )
        ],
      ),
    );
  }
}

class Nav {
  final DrawerStatus drawerStatus;
  final String title;
  final IconData icon;
  Nav({
    required this.drawerStatus,
    required this.title,
    required this.icon,
  });
}
