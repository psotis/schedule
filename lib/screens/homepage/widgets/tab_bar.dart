// ignore_for_file: public_member_api_docs, sort_constructors_firs
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';
import 'package:scheldule/widgets/add_appointment.dart';
import 'package:scheldule/widgets/add_patient.dart';

class TabWidget extends StatefulWidget {
  final User? user;
  bool isMobile;
  TabWidget({
    super.key,
    this.user,
    required this.isMobile,
  });

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return SizedBox(
      child: Column(
        children: [
          TabBar(controller: _tabController, tabs: [
            // SizedBox(
            //   height: ScreenSize.screenHeight * .08,
            //   width: ScreenSize.screenWidth * .2,
            //   child: Align(
            //     alignment: Alignment.center,
            //     child: Text(
            //       'Πρόγραμμα',
            //       style: TextStyle(fontSize: widget.isMobile == true ? 12 : 14),
            //     ),
            //   ),
            // ),
            SizedBox(
              height: ScreenSize.screenHeight * .08,
              width: ScreenSize.screenWidth * .2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Προσθήκη ραντεβού',
                  style: TextStyle(fontSize: widget.isMobile == true ? 12 : 14),
                ),
              ),
            ),
            SizedBox(
              height: ScreenSize.screenHeight * .08,
              width: ScreenSize.screenWidth * .2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Προσθήκη ασθενή',
                  style: TextStyle(fontSize: widget.isMobile == true ? 12 : 14),
                ),
              ),
            ),

            // Tab(
            //   text: 'See scheldule',
            // ),
            // Tab(
            //   text: 'Add a user',
            // ),
            // Tab(
            //   text: 'Add appointment',
            // ),
          ]),
          Expanded(
            flex: 1,
            child: TabBarView(
              controller: _tabController,
              children: [
                // SeeScheldule(user: widget.user),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AddAppointment(
                    user: widget.user,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AddPatient(
                    user: widget.user,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
