import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/search%20user/search_user_provider.dart';
import 'package:scheldule/screens/calendar/widgets/customer_side.dart';
import 'package:scheldule/screens/calendar/widgets/customer_side_mobile.dart';
import 'package:scheldule/styling/fonts/textstyle.dart';
import 'package:scheldule/utils/colors.dart';
import 'package:scheldule/utils/cutom_text.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:scheldule/models/appointment_model.dart' as app;

import '../../constants/device_sizes.dart';
import '../../repositories/api_client.dart';
import '../../repositories/appointment_repository.dart';

class SyncFusionCalendar extends StatefulWidget {
  const SyncFusionCalendar({super.key});

  @override
  State<SyncFusionCalendar> createState() => _SyncFusionCalendarState();
}

class _SyncFusionCalendarState extends State<SyncFusionCalendar> {
  final CalendarController _controller = CalendarController();
  List<AppointMent> appointment = [];
  Stream<List<app.AppointMent>>? stream;
  Stream<List<app.AppointMent>>? streamToday;

  @override
  void initState() {
    super.initState();
    _controller.displayDate = DateTime.now();
    final repository = context.read<AppointmentRepository>();
    stream = repository.streamAppointment();
    streamToday = repository.streamTodayAppointment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().initEmployees();
    });
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
                  child: Center(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () async {
                            context
                                .read<AppointmentProvider>()
                                .deleteAppointments(
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
    required DateTime selectedDay1,
    required DateTime endOfDay,
  }) async {
    context.read<AppointmentProvider>().getAppointMents(selectedDay1, endOfDay);
  }

  int _appointmentDuration(app.AppointMent appointment) {
    if (appointment.totalDurationMinutes > 0) {
      return appointment.totalDurationMinutes;
    }
    return 60;
  }

  Future<void> _rescheduleAppointment(
    AppointmentDragEndDetails details,
    List<app.AppointMent> appointments,
  ) async {
    final calendarAppointment = details.appointment;
    final droppingTime = details.droppingTime;
    if (calendarAppointment is! AppointMent || droppingTime == null) return;

    app.AppointMent? appointmentToMove;
    for (final appointment in appointments) {
      if (appointment.id == calendarAppointment.id) {
        appointmentToMove = appointment;
        break;
      }
    }
    if (appointmentToMove == null || appointmentToMove.date == null) return;

    final previousStart = appointmentToMove.date!.toDate();
    if (previousStart.isAtSameMomentAs(droppingTime)) return;

    try {
      await context.read<AppointmentRepository>().rescheduleAppointment(
            appointment: appointmentToMove,
            start: droppingTime,
          );
      if (!mounted) return;
      snackBarDialog(
        context,
        color: Colors.green,
        message:
            'Το ραντεβού μεταφέρθηκε στις ${DateFormat('dd-MM-yyyy HH:mm').format(droppingTime)}',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {});
      snackBarDialog(
        context,
        color: Colors.red,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {});
      snackBarDialog(
        context,
        color: Colors.red,
        message: 'Δεν ήταν δυνατή η μεταφορά του ραντεβού',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DeviceSizes.mobileSize) {
          return _mobile();
        } else {
          return _desktop();
        }
      },
    );
  }

  Row _desktop() {
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
              if (snapshot.hasError) {
                return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
              }
              final appointments = (snapshot.data ?? <app.AppointMent>[])
                  .where((appointment) => appointment.date != null)
                  .toList();

              final employeeProvider = context.watch<EmployeeProvider>();

              final Map<String, Color> employeeColorMap = {
                for (final emp in employeeProvider.employees)
                  '${emp.name} ${emp.surname}':
                      hexToColors(emp.color) ?? Colors.blueAccent,
              };
              return Card(
                child: SfCalendar(
                  allowDragAndDrop: true,
                  controller: _controller,
                  showNavigationArrow: true,
                  showDatePickerButton: true,
                  allowViewNavigation: true,
                  view: CalendarView.workWeek,
                  firstDayOfWeek: DateTime.monday,
                  timeSlotViewSettings: TimeSlotViewSettings(
                    timeIntervalHeight: 50,
                    startHour: 7,
                    endHour: 23,
                    timeFormat: 'HH:mm',
                    nonWorkingDays: <int>[DateTime.saturday, DateTime.sunday],
                  ),
                  headerDateFormat: 'y MMMM',
                  minDate: DateTime(2022, 1, 1, 10, 0, 00, 000),
                  maxDate: DateTime(2100, 1, 1, 10, 0, 00, 000),
                  allowedViews: [
                    CalendarView.workWeek,
                    CalendarView.week,
                    CalendarView.day,
                  ],
                  appointmentBuilder: (context, calendarAppointmentDetails) {
                    final List appointments =
                        calendarAppointmentDetails.appointments.toList();
                    final AppointMent appointment = appointments[0];
                    final appoint = calendarAppointmentDetails
                        .appointments.first as AppointMent;
                    return Container(
                        decoration: BoxDecoration(
                            color: appoint.background,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Center(
                            child: Text(appointment.eventName,
                                textAlign: TextAlign.center,
                                style: TextStyles().appointments)));
                  },
                  onTap: calendarPicker,
                  onDragEnd: (details) =>
                      _rescheduleAppointment(details, appointments),
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                  ),
                  dataSource: MeetingDataSource(appointments.map((e) {
                    return AppointMent(
                      '${e.name} ${e.surname}',
                      e.id,
                      e.date!.toDate(),
                      e.date!.toDate().add(
                            Duration(minutes: _appointmentDuration(e)),
                          ),
                      employeeColorMap[e.employee] ?? Colors.blueAccent,
                      e.surname,
                      e.phone,
                      e.email,
                      e.address,
                      e.paid,
                      e.amka,
                    );
                  }).toList()),
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
              if (snapshot.hasError) {
                return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
              }
              final appointments = snapshot.data ?? <app.AppointMent>[];
              if (appointments.isEmpty) {
                return Center(child: Text('Δεν βρέθηκαν σημερινά ραντεβού'));
              }

              int todaysIncome = 0;
              for (var i = 0; i < appointments.length; i++) {
                todaysIncome += appointments[i].paid ?? 0;
              }

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomText(
                          text: 'Σημερινά Ραντεβού',
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        CustomText(
                          text: '-',
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        CustomText(
                          text: 'Σημερινό Εισόδημα: $todaysIncome €',
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(10),
                        shrinkWrap: true,
                        itemCount: snapshot.data?.length,
                        itemBuilder: (context, index) {
                          var appoint = snapshot.data?[index];

                          return GestureDetector(
                            onTap: () async {
                              final List<app.AppointMent> customer =
                                  await context
                                      .read<SearchUserProvider>()
                                      .searchUsers();
                              if (!context.mounted) return;

                              final finalCustomer = customer.firstWhere(
                                (cus) =>
                                    cus.name == appoint.name &&
                                    cus.surname == appoint.surname,
                                orElse: () => app.AppointMent.initial(),
                              );

                              await _showSideDialog(
                                  context, finalCustomer, appoint);
                            },
                            child: Card(
                              child: Dismissible(
                                key: Key(appoint!.id),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Διαγραφή ραντεβού με ${appoint.name} ${appoint.surname}?'),
                                        actions: [
                                          SendButton(
                                              backgroundColor: Colors.green,
                                              icon: Icons.thumb_up_outlined,
                                              onPressed: () {
                                                context
                                                    .read<AppointmentProvider>()
                                                    .deleteAppointments(
                                                        appoint.id.toString());
                                                snackBarDialog(context,
                                                    color: Colors.red,
                                                    message:
                                                        'Το ραντεβού με πελάτη ${appoint.name} ${appoint.surname} διαγράφθηκε');
                                                Navigator.pop(context, true);
                                              },
                                              text: 'Ναι'),
                                          SendButton(
                                              backgroundColor: Colors.red,
                                              icon: Icons.delete,
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              text: 'Όχι')
                                        ],
                                      );
                                    },
                                  );
                                },
                                direction: DismissDirection.startToEnd,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child:
                                      Icon(Icons.delete, color: Colors.white),
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${appoint.name} ${appoint.surname}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  leading: appoint.date != null
                                      ? Text(
                                          DateFormat('dd-MM-yyyy HH:mm')
                                              .format(appoint.date!.toDate()),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.red),
                                        )
                                      : Text(
                                          'Ημερομηνία άγνωστη',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appoint.employee ?? '',
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
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Future<Object?> _showSideDialog(
      BuildContext context, app.AppointMent customer, app.AppointMent appoint) {
    return showGeneralDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10))),
              width: 500,
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomerSide(
                  customer: customer,
                  appointMent: appoint,
                ),
              ),
            ),
          );
        });
  }

  SingleChildScrollView _mobile() {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.today_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Το πρόγραμμά σου σήμερα',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        _friendlyDate(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
                }
                final appointments = (snapshot.data ?? <app.AppointMent>[])
                    .where((appointment) => appointment.date != null)
                    .toList();

                final employeeProvider = context.watch<EmployeeProvider>();

                final Map<String, Color> employeeColorMap = {
                  for (final emp in employeeProvider.employees)
                    '${emp.name} ${emp.surname}':
                        hexToColors(emp.color) ?? Colors.blueAccent,
                };
                return SizedBox(
                  height: 470,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: SfCalendar(
                      allowDragAndDrop: true,
                      controller: _controller,
                      showNavigationArrow: true,
                      showDatePickerButton: true,
                      allowViewNavigation: true,
                      view: CalendarView.day,
                      firstDayOfWeek: DateTime.monday,
                      timeSlotViewSettings: TimeSlotViewSettings(
                        timeInterval: const Duration(minutes: 30),
                        timeIntervalHeight: 54,
                        startHour: 7,
                        endHour: 23,
                        timeFormat: 'HH:mm',
                        nonWorkingDays: <int>[
                          DateTime.saturday,
                          DateTime.sunday
                        ],
                      ),
                      headerDateFormat: 'EEEE, d MMMM',
                      headerStyle: CalendarHeaderStyle(
                        textAlign: TextAlign.left,
                        backgroundColor: colors.surface,
                        textStyle: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      viewHeaderStyle: ViewHeaderStyle(
                        backgroundColor: colors.surface,
                        dayTextStyle: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        dateTextStyle: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      minDate: DateTime(2022, 1, 1, 10, 0, 00, 000),
                      maxDate: DateTime(2100, 1, 1, 10, 0, 00, 000),
                      allowedViews: [
                        CalendarView.day,
                        CalendarView.week,
                      ],
                      appointmentBuilder:
                          (context, calendarAppointmentDetails) {
                        final List appointments =
                            calendarAppointmentDetails.appointments.toList();
                        final AppointMent appointment = appointments[0];
                        final appoint = calendarAppointmentDetails
                            .appointments.first as AppointMent;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appoint.background,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              appointment.eventName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles().appointments,
                            ),
                          ),
                        );
                      },
                      onTap: calendarPicker,
                      onDragEnd: (details) =>
                          _rescheduleAppointment(details, appointments),
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                      ),
                      dataSource: MeetingDataSource(appointments.map((e) {
                        return AppointMent(
                          '${e.name} ${e.surname}',
                          e.id,
                          e.date!.toDate(),
                          e.date!.toDate().add(
                                Duration(minutes: _appointmentDuration(e)),
                              ),
                          employeeColorMap[e.employee] ?? Colors.blueAccent,
                          e.surname,
                          e.phone,
                          e.email,
                          e.address,
                          // e.description,
                          e.paid,
                          e.amka,
                        );
                      }).toList()),
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
                if (snapshot.hasError) {
                  return Center(child: Text('Αδύνατη η φόρτωση ραντεβού'));
                }
                final appointments = snapshot.data ?? <app.AppointMent>[];
                if (appointments.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: colors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Δεν υπάρχουν άλλα σημερινά ραντεβού',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  );
                }

                int todaysIncome = 0;
                for (var i = 0; i < appointments.length; i++) {
                  todaysIncome += appointments[i].paid ?? 0;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    child: Column(
                      spacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withAlpha(120),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TodayMetric(
                                  label: 'Ραντεβού',
                                  value: appointments.length.toString(),
                                  icon: Icons.event_note_rounded,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 38,
                                color: colors.outlineVariant,
                              ),
                              Expanded(
                                child: _TodayMetric(
                                  label: 'Έσοδα ημέρας',
                                  value: '$todaysIncome €',
                                  icon: Icons.payments_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...List.generate(appointments.length, (index) {
                          var appoint = appointments[index];
                          return InkWell(
                            onTap: () async {
                              final List<app.AppointMent> customer =
                                  await context
                                      .read<SearchUserProvider>()
                                      .searchUsers();
                              if (!context.mounted) return;

                              final finalCustomer = customer.firstWhere(
                                (cus) =>
                                    cus.name == appoint.name &&
                                    cus.surname == appoint.surname,
                                orElse: () => app.AppointMent.initial(),
                              );
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerSideMobile(
                                      customer: finalCustomer,
                                      appointMent: appoint,
                                    ),
                                  ));
                            },
                            child: Dismissible(
                              key: Key(appoint.id),
                              confirmDismiss: (direction) {
                                return showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Διαγραφή ραντεβού με ${appoint.name} ${appoint.surname}?'),
                                      actions: [
                                        SendButton(
                                            backgroundColor: Colors.green,
                                            icon: Icons.thumb_up_outlined,
                                            onPressed: () async {
                                              await context
                                                  .read<AppointmentProvider>()
                                                  .deleteAppointments(
                                                      appoint.id.toString());
                                              if (!context.mounted) return;
                                              snackBarDialog(context,
                                                  color: Colors.red,
                                                  message:
                                                      'Το ραντεβού με πελάτη ${appoint.name} ${appoint.surname} διαγράφθηκε');
                                              Navigator.pop(context, true);
                                            },
                                            text: 'Ναι'),
                                        SendButton(
                                            backgroundColor: Colors.red,
                                            icon: Icons.delete,
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            text: 'Όχι')
                                      ],
                                    );
                                  },
                                );
                              },
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: colors.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colors.onErrorContainer,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Text(
                                        appoint.date == null
                                            ? '--:--'
                                            : DateFormat('HH:mm').format(
                                                appoint.date!.toDate(),
                                              ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.onPrimaryContainer,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${appoint.name} ${appoint.surname}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              appoint.employee ?? '',
                                              appoint.position ?? '',
                                            ]
                                                .where(
                                                  (value) =>
                                                      value.trim().isNotEmpty,
                                                )
                                                .join(' • '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  String _friendlyDate(DateTime date) {
    const weekdays = [
      'Δευτέρα',
      'Τρίτη',
      'Τετάρτη',
      'Πέμπτη',
      'Παρασκευή',
      'Σάββατο',
      'Κυριακή',
    ];
    const months = [
      'Ιανουαρίου',
      'Φεβρουαρίου',
      'Μαρτίου',
      'Απριλίου',
      'Μαΐου',
      'Ιουνίου',
      'Ιουλίου',
      'Αυγούστου',
      'Σεπτεμβρίου',
      'Οκτωβρίου',
      'Νοεμβρίου',
      'Δεκεμβρίου',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _TodayMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TodayMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21, color: colors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MeetingDataSource extends CalendarDataSource<AppointMent> {
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

  // String getDescription(int index) {
  //   return appointments![index].description;
  // }

  @override
  String getRecurrenceRule(int index) {
    return appointments![index].recurrenceRule;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  AppointMent convertAppointmentToObject(
    AppointMent customData,
    Appointment appointment,
  ) {
    return AppointMent(
      appointment.subject,
      customData.id,
      appointment.startTime,
      appointment.endTime,
      appointment.color,
      customData.surname,
      customData.phone,
      customData.email,
      customData.address,
      customData.paid,
      appointment.recurrenceRule ?? '',
    );
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
    this.paid,
    // this.description,
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
  int? paid;
  // String description;
  String recurrenceRule;

  // bool isAllDay;
}
