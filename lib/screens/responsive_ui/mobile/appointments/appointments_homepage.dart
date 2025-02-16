// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/providers/add%20appointment/add_appointment_provider.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';

import '../../../../utils/custom_text_form.dart';
import '../../../homepage/widgets/calendar_widget.dart';

class Appointments extends StatefulWidget {
  final User? user;
  Appointments({
    super.key,
    this.user,
  });

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  String? name, surname, email, phone, address, description;

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController controller = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  DateTime? finalDate;
  String? formattedTime;

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();
    await context.read<AddAppointmentProvider>().addAppointment(
          userUid: widget.user!.uid,
          name: name!,
          surname: surname!,
          date: timestampday,
          // phone: phone!,
          // email: email!,
          // address: address!,
          // description: description!,
        );
  }

  // void addAppointment({
  //   required String userId,
  //   required DateTime selectedDay,
  //   required DateTime endOfDay,
  // }) async {
  //   await Future.delayed(Duration(), () {
  //     context
  //         .read<AppointmentProvider>()
  //         .getAppointMents(userId, selectedDay, endOfDay);
  //   });
  // }

  Future pickDateTime() async {
    DateTime? date = await pickDate();
    if (date == null) return;

    TimeOfDay? time = await pickTime();
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      finalDate = dateTime;
      formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(finalDate!);
      timestampday = Timestamp.fromDate(finalDate!);
    });
  }

  Future<DateTime?> pickDate() {
    return showDatePicker(
      locale: Locale('el'),
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
  }

  Future<TimeOfDay?> pickTime() {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.inputOnly,
      context: context,
      initialTime: TimeOfDay(
        hour: selectedDateTime.hour,
        minute: selectedDateTime.minute,
      ),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Localizations.override(
          context: context,
          locale: const Locale('el', 'GR'),
          child: child!,
        ),
      ),
    );
  }

  @override
  void initState() {
    controller = TextEditingController();
    nameController = TextEditingController();
    surnameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    nameController.dispose();
    surnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          spacing: 20,
          children: [
            CustomTextForm(
              labelText: 'Name',
              hintText: 'John',
              prefixIcon: Icons.person,
            ),
            CustomTextForm(
              labelText: 'Surname',
              hintText: 'Doe',
              prefixIcon: Icons.person_2,
            ),
            CustomTextForm(
              labelText: 'E-mail',
              hintText: 'example@gmail.com',
              prefixIcon: Icons.email,
            ),
            Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pick a date'),
                OutlinedButton(
                    onPressed: pickDateTime,
                    child: formattedTime == null
                        ? Icon(Icons.date_range)
                        : Text(formattedTime!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
