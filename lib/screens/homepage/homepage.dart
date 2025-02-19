import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/device_sizes.dart';
import 'package:scheldule/screens/homepage/widgets/syncfusion_calendar.dart';

import '../../constants/screen%20sizes/screen_sizes.dart';
import '../../providers/providers.dart';
import 'widgets/search.dart';
import 'widgets/tab_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool check = false;
  bool selected = false;
  double selectedWidthActive = 0;
  double selectedHeightActive = 0;

  @override
  void initState() {
    // callInitialAppointments();
    print(user!.uid);
    // print(selectedDay1.toUtc());
    // print(endOfDay.toUtc());
    context.read<SearchUserProvider>().searchUsers(user: user!.uid);

    super.initState();
  }

  // Future callInitialAppointments() async {
  //   await Future.delayed(Duration(), () {
  //     context
  //         .read<AppointmentProvider>()
  //         .getAppointMents(user!.uid, selectedDay1.toUtc(), endOfDay.toUtc());
  //   });
  //   print('Call init appointments');
  // }

  bool isMobile = false;

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    double selectedWidthActive = ScreenSize.screenWidth * .2;
    double selectedHeightActive = ScreenSize.screenHeight * .1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxHeight > DeviceSizes.mobileHeight &&
              constraints.maxWidth > DeviceSizes.mobileWidth) {
            isMobile = false;
            return Row(
              children: [
                welcomeRow(selectedWidthActive, selectedHeightActive,
                    ScreenSize.screenWidth * .12),
                SizedBox(
                  height: ScreenSize.screenHeight,
                  width: ScreenSize.screenWidth * .60,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SyncFusionCalendar(user: user!),
                  ),
                ),
                VerticalDivider(width: 2, thickness: 2),
                Expanded(
                  child: TabWidget(user: user, isMobile: isMobile),
                ),
              ],
            );
          } else {
            isMobile = true;
            return PopScope(
              canPop: false,
              child: Scaffold(
                appBar: AppBar(),
                drawer: welcomeRow(ScreenSize.screenWidth * .4,
                    ScreenSize.screenHeight * .1, ScreenSize.screenWidth * .60),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: ScreenSize.screenHeight * .9,
                        width: ScreenSize.screenWidth,
                        child: SyncFusionCalendar(user: user!),
                      ),
                      Divider(),
                      SizedBox(
                        height: ScreenSize.screenHeight * 1.2,
                        width: double.infinity,
                        child: TabWidget(user: user, isMobile: isMobile),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  Container welcomeRow(
      double selectedWidthActive, double selectedHeightActive, double width) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 189, 143, 228),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(144, 0, 0, 0),
            blurRadius: 15.0,
            spreadRadius: .02,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
      height: ScreenSize.screenHeight,
      width: width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Καλώς ήρθες'),
                  TextSpan(text: ' '),
                  TextSpan(
                      text: '${user!.email}',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            // Text('Καλώς ήρθες ${user!.email}'),
          ),
          // ElevatedButton.icon(
          //   onPressed: () =>
          //       context.read<SearchUserProvider>().searchUsers(),
          //   icon: Icon(Icons.add),
          //   label: Text('Appointment'),
          // ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                selected = true;
                selectedWidthActive = ScreenSize.screenWidth * .4;
                selectedHeightActive = ScreenSize.screenHeight * .4;
              });
            },
            child: AnimatedContainer(
              duration: Duration(seconds: 4),
              curve: Curves.fastEaseInToSlowEaseOut,
              child: !selected
                  ? Icon(Icons.search)
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        width: selected ? selectedWidthActive : 100,
                        height: selected ? selectedHeightActive : 100,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Search(
                            user: user,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          SizedBox(height: 20),
          Divider(height: 2, color: Colors.yellow),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: logout,
            icon: Icon(Icons.logout),
            label: Text('Έξοδος'),
          ),
          // ElevatedButton(
          //     onPressed: () =>
          //         SearchEditUserRepository().patientAppointmentLength(),
          //     child: Text('See user')),
          // ElevatedButton.icon(
          //   onPressed: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //           builder: (context) => TestStream(user: user))),
          //   icon: Icon(Icons.logout),
          //   label: Text('See StreamTest'),
          // ),
        ],
      ),
    );
  }

  Future logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
