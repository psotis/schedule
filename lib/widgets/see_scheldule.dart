// ignore_for_file: public_member_api_docs, sort_SeeSchelduletructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/screens/homepage/widgets/calendar_widget.dart';

import '../providers/appointment/appointment_status.dart';
import '../providers/providers.dart';

class SeeScheldule extends StatefulWidget {
  User? user;
  SeeScheldule({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  State<SeeScheldule> createState() => _SeeSchelduleState();
}

class _SeeSchelduleState extends State<SeeScheldule> {
  void onDeleteAppointment(String userId, String appointmentId) async {
    await context
        .read<AppointmentProvider>()
        .deleteAppointments(userId, appointmentId);

    // ignore: use_build_context_synchronously
    context
        .read<AppointmentProvider>()
        .getAppointMents(widget.user!.uid, selectedDay1, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
        builder: (context, appointment, child) {
      if (appointment.appointmentState.appointmentStatus ==
          AppointmentStatus.loading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (appointment.appointmentState.appointmentStatus ==
          AppointmentStatus.empty) {
        return Center(
          child: Text(
            'Empty list',
            style: TextStyle(color: Colors.red, fontSize: 40),
          ),
        );
      }
      if (appointment.appointmentState.appointmentStatus ==
          AppointmentStatus.delete) {
        context
            .read<AppointmentProvider>()
            .getAppointMents(widget.user!.uid, selectedDay1, endOfDay);
      }
      if (appointment.appointmentState.appointmentStatus ==
          AppointmentStatus.delete) {
        context
            .read<AppointmentProvider>()
            .getAppointMents(widget.user!.uid, selectedDay1, endOfDay);
      }
      return ListView.builder(
        shrinkWrap: true,
        itemCount: appointment.appointment.length,
        itemBuilder: (BuildContext context, int index) {
          var p = appointment.appointment[index];

          return Column(
            children: [
              SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: Text('${p.name} ${p.surname}'),
                  leading: Text(
                    p.date!.toDate().toString().substring(5, 16),
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () =>
                        onDeleteAppointment(widget.user!.uid, p.id),
                  ),
                ),
              ),
              Divider(),
            ],
          );
        },
      );
    });
  }
}
