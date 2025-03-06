import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';
import 'package:scheldule/styling/fonts/textstyle.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:scheldule/models/appointment_model.dart' as app;

import '../../constants/device_sizes.dart';
import '../../repositories/appointment_repository.dart';

class SyncFusionCalendar extends StatefulWidget {
  final User user;
  const SyncFusionCalendar({super.key, required this.user});

  @override
  State<SyncFusionCalendar> createState() => _SyncFusionCalendarState();
}

class _SyncFusionCalendarState extends State<SyncFusionCalendar> {
  final CalendarController _controller = CalendarController();
  List<AppointMent> appointment = [];
  String? userId;

  Stream<List<app.AppointMent>>? stream;
  Stream<List<app.AppointMent>>? streamToday;

  @override
  void initState() {
    super.initState();
    userId = widget.user.uid;
    stream = AppointmentRepository().streamAppointment(userId: userId!);
    streamToday =
        AppointmentRepository().streamTodayAppointment(userId: userId!);
  }

  void calendarPicker(CalendarTapDetails details) async {
    if (details.targetElement == CalendarElement.appointment) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: null,
                            icon: Icon(Icons.edit),
                          ),
                          Text('Επεξεργασία'),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () async {
                              context
                                  .read<AppointmentProvider>()
                                  .deleteAppointments(widget.user.uid,
                                      details.appointments![0].id.toString());
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                          Text('Διαγραφή'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Future<void> showEditDialog(AppointMent appointment) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        print('This is the ID: ${appointment.id}');
        return Center(
          child: Container(
            height: 300,
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ασθενης: ${appointment.eventName}',
                    style: TextStyles().seeAppointment,
                  ),
                  Text(
                    'Ραντεβού: ${appointment.from.toString()}',
                    style: TextStyles().seeAppointment,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteAppointment({
    required String userId,
    required DateTime selectedDay1,
    required DateTime endOfDay,
  }) async {
    context
        .read<AppointmentProvider>()
        .getAppointMents(userId, selectedDay1, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DeviceSizes.mobileSize) {
          return SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return SizedBox(
                      height: 400,
                      child: Card(
                        child: SfCalendar(
                          allowDragAndDrop: true,
                          controller: _controller,
                          showNavigationArrow: true,
                          showDatePickerButton: true,
                          allowViewNavigation: true,
                          view: CalendarView.week,
                          firstDayOfWeek: DateTime.monday,
                          timeSlotViewSettings: TimeSlotViewSettings(
                            timeIntervalHeight: 50,
                            startHour: 7,
                            endHour: 23,
                            timeFormat: 'HH:mm',
                            nonWorkingDays: <int>[
                              DateTime.saturday,
                              DateTime.sunday
                            ],
                          ),
                          headerDateFormat: 'y MMMM',
                          minDate: DateTime(2022, 1, 1, 10, 0, 00, 000),
                          maxDate: DateTime(2100, 1, 1, 10, 0, 00, 000),
                          allowedViews: [
                            CalendarView.workWeek,
                            CalendarView.week,
                            CalendarView.day,
                          ],
                          appointmentBuilder:
                              (context, calendarAppointmentDetails) {
                            final List appointments = calendarAppointmentDetails
                                .appointments
                                .toList();
                            final AppointMent appointment = appointments[0];
                            return Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade400,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                child: Center(
                                    child: Text(appointment.eventName,
                                        textAlign: TextAlign.center,
                                        style: TextStyles().appointments)));
                          },
                          onTap: calendarPicker,
                          monthViewSettings: const MonthViewSettings(
                            appointmentDisplayMode:
                                MonthAppointmentDisplayMode.appointment,
                          ),
                          dataSource: MeetingDataSource(snapshot.data!
                              .map((e) => AppointMent(
                                    '${e.name} ${e.surname}',
                                    e.id,
                                    e.date!.toDate(),
                                    e.date!.toDate().add(Duration(hours: 1)),
                                    Colors.blueAccent,
                                    e.surname,
                                    e.phone,
                                    e.email,
                                    e.address,
                                    e.description,
                                    e.amka,
                                  ))
                              .toList()),
                        ),
                      ),
                    );
                  },
                ),
                StreamBuilder(
                  stream: streamToday,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No appointments found'));
                    }
                    return SizedBox(
                      height: 500,
                      child: Column(
                        children: [
                          Text('Todays appointments'),
                          ListView.builder(
                            padding: EdgeInsets.all(10),
                            shrinkWrap: true,
                            itemCount: snapshot.data?.length,
                            itemBuilder: (context, index) {
                              var appoint = snapshot.data?[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      '${appoint!.name} ${appoint.surname}'),
                                  leading: Text(DateFormat('dd-MM-yyyy HH:mm')
                                      .format(appoint.date!.toDate())),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(appoint.employee ?? ''),
                                      Text(appoint.position ?? '')
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: StreamBuilder(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return Card(
                      child: SfCalendar(
                        allowDragAndDrop: true,
                        controller: _controller,
                        showNavigationArrow: true,
                        showDatePickerButton: true,
                        allowViewNavigation: true,
                        view: CalendarView.week,
                        firstDayOfWeek: DateTime.monday,
                        timeSlotViewSettings: TimeSlotViewSettings(
                          timeIntervalHeight: 50,
                          startHour: 7,
                          endHour: 23,
                          timeFormat: 'HH:mm',
                          nonWorkingDays: <int>[
                            DateTime.saturday,
                            DateTime.sunday
                          ],
                        ),
                        headerDateFormat: 'y MMMM',
                        minDate: DateTime(2022, 1, 1, 10, 0, 00, 000),
                        maxDate: DateTime(2100, 1, 1, 10, 0, 00, 000),
                        allowedViews: [
                          CalendarView.workWeek,
                          CalendarView.week,
                          CalendarView.day,
                        ],
                        appointmentBuilder:
                            (context, calendarAppointmentDetails) {
                          final List appointments =
                              calendarAppointmentDetails.appointments.toList();
                          final AppointMent appointment = appointments[0];
                          return Container(
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              child: Center(
                                  child: Text(appointment.eventName,
                                      textAlign: TextAlign.center,
                                      style: TextStyles().appointments)));
                        },
                        onTap: calendarPicker,
                        monthViewSettings: const MonthViewSettings(
                          appointmentDisplayMode:
                              MonthAppointmentDisplayMode.appointment,
                        ),
                        dataSource: MeetingDataSource(snapshot.data!
                            .map((e) => AppointMent(
                                  '${e.name} ${e.surname}',
                                  e.id,
                                  e.date!.toDate(),
                                  e.date!.toDate().add(Duration(hours: 1)),
                                  Colors.blueAccent,
                                  e.surname,
                                  e.phone,
                                  e.email,
                                  e.address,
                                  e.description,
                                  e.amka,
                                ))
                            .toList()),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                flex: 1,
                child: StreamBuilder(
                  stream: streamToday,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No appointments found'));
                    }
                    return Column(
                      children: [
                        Text('Todays appointments'),
                        ListView.builder(
                          padding: EdgeInsets.all(10),
                          shrinkWrap: true,
                          itemCount: snapshot.data?.length,
                          itemBuilder: (context, index) {
                            var appoint = snapshot.data?[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '${appoint!.name} ${appoint.surname}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: Text(
                                  DateFormat('dd-MM-yyyy HH:mm')
                                      .format(appoint.date!.toDate()),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        appoint.employee ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        appoint.position ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              )
            ],
          );
        }
      },
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<AppointMent> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  String getId(int index) {
    return appointments![index].id;
  }

  String getDescription(int index) {
    return appointments![index].description;
  }

  @override
  String getRecurrenceRule(int index) {
    return appointments![index].recurrenceRule;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }
}

class AppointMent extends CalendarDataSource {
  AppointMent(
    this.eventName,
    this.id,
    this.from,
    this.to,
    this.background,
    this.surname,
    this.phone,
    this.email,
    this.address,
    this.description,
    this.recurrenceRule,
  );

  String eventName;
  String id;
  DateTime from;
  DateTime to;
  Color background;
  String surname;
  String phone;
  String email;
  String address;
  String description;
  String recurrenceRule;

  // bool isAllDay;
}
