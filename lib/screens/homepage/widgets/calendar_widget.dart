import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/providers.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../constants/screen%20sizes/screen_sizes.dart';
import '../../../models/appointment_model.dart';

DateTime initialDate = DateTime.now();
DateTime selectedDay1 =
    DateTime(initialDate.year, initialDate.month, initialDate.day, 2, 0, 0, 0);
DateTime startOfDay = DateTime(
    initialDate.year, initialDate.month, initialDate.day, 23, 59, 99, 999);
DateTime endOfDay = DateTime(
    initialDate.year, initialDate.month, initialDate.day, 23, 59, 0, 0);
Timestamp timestampday = Timestamp.fromDate(selectedDay1);

class Calendar extends StatefulWidget {
  final User user;
  bool isMobile;
  Calendar({super.key, required this.user, required this.isMobile});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<AppointMent>>? selectedEvents;

  List<AppointMent> _getEventsfromDay(DateTime date) {
    return selectedEvents?[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      clipBehavior: Clip.antiAlias,
      child: TableCalendar(
        locale: 'el_GR',
        rowHeight: ScreenSize.screenHeight * .15,
        headerStyle: HeaderStyle(
          // decoration: BoxDecoration(color: Color.fromARGB(255, 189, 143, 228)),
          formatButtonVisible: false,
          // headerMargin: EdgeInsets.only(bottom: 100),
          titleCentered: true,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: ScreenSize.screenHeight * .03),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          formatButtonTextStyle: const TextStyle(color: Colors.white),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
        ),
        daysOfWeekStyle:
            DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white)),
        calendarStyle: CalendarStyle(
          //! Check this
          weekNumberTextStyle:
              TextStyle(color: Color.fromARGB(255, 189, 143, 228)),
          weekendTextStyle: TextStyle(color: Colors.red),

          defaultTextStyle: TextStyle(color: Colors.white),
          cellMargin: widget.isMobile == false
              ? EdgeInsets.all(30)
              : EdgeInsets.all(12),
          selectedDecoration: BoxDecoration(
            color: Color.fromARGB(255, 189, 143, 228),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Color.fromARGB(255, 189, 143, 228).withAlpha(80),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Color.fromARGB(255, 189, 143, 228),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            if (day.weekday == DateTime.sunday ||
                day.weekday == DateTime.saturday) {
              final text = DateFormat.E().format(day);

              return Center(
                child: Text(
                  text,
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            return null;
          },
        ),
        selectedDayPredicate: (day) {
          return isSameDay(selectedDay1, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            selectedDay1 = selectedDay;
            endOfDay = focusedDay.add(Duration(hours: 23, minutes: 59));
            startOfDay = DateTime(
                selectedDay1.year, selectedDay1.month, selectedDay1.day);
            // endOfDay = DateTime(selectedDay1.year, selectedDay1.month,
            //     selectedDay1.day, 23, 59, 59, 999);
            timestampday = Timestamp.fromDate(selectedDay1);
            print(startOfDay);
            // _focusedDay = focusedDay;
            print('This is the selectedDay: $selectedDay');
            print('This is the focusedDay: $focusedDay');

            print(
                'This is the focused day with add.duration ${selectedDay.add(Duration(hours: 23, minutes: 59))}');
          });
          context.read<AppointmentProvider>().getAppointMents(widget.user.uid,
              selectedDay, selectedDay.add(Duration(hours: 23, minutes: 59)));
        },
        eventLoader: _getEventsfromDay,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: ((focusedDay) {
          focusedDay = focusedDay;
        }),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 12, 1),
      ),
    );
  }
}
