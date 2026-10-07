// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/add_appointment.dart';
import 'package:scheldule/screens/responsive_ui/mobile/appointments/appointment_history.dart';

import '../../../../constants/screen sizes/screen_sizes.dart';

class Appointments extends StatefulWidget {
  const Appointments({
    super.key,
  });

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // void _dismissKeyboard(BuildContext context) {
  //   FocusScope.of(context).requestFocus(FocusNode());
  // }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          TabBar(controller: _tabController, tabs: [
            SizedBox(
              height: ScreenSize.screenHeight * .08,
              width: ScreenSize.screenWidth * .2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Προσθήκη ραντεβού',
                ),
              ),
            ),
            SizedBox(
              height: ScreenSize.screenHeight * .08,
              width: ScreenSize.screenWidth * .2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Ιστορικό',
                ),
              ),
            ),
          ]),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                Tab(
                  child: AddAppointments(),
                ),
                Tab(
                  child: AppointmentHistory(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
