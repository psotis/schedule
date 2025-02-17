// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';

import 'package:scheldule/screens/homepage/widgets/search.dart';
import 'package:scheldule/utils/send_button.dart';

import '../../../../providers/add appointment/add_appointment_provider.dart';
import '../../../../utils/custom_text_form.dart';

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
  String? name, surname;

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  late Timestamp timestampday;

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
        date: timestampday);

    setState(() {
      nameController.clear();
      surnameController.clear();
      formattedTime = null;
    });
  }

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
    nameController = TextEditingController();
    surnameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        spacing: 20,
        children: [Search(user: widget.user), _form(), Spacer(), _sendButton()],
      ),
    );
  }

  Form _form() {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 20,
        children: [
          CustomTextForm(
            controller: nameController,
            labelText: 'Name',
            hintText: 'John',
            prefixIcon: Icons.person,
            onChanged: (value) {
              setState(() {
                nameController.text == value;
              });
            },
            onSaved: (value) {
              name = value;
            },
          ),
          CustomTextForm(
            controller: surnameController,
            labelText: 'Surname',
            hintText: 'Doe',
            prefixIcon: Icons.person_2,
            onChanged: (value) {
              setState(() {
                surnameController.text == value;
              });
            },
            onSaved: (value) {
              surname = value;
            },
          ),
          _pickDate(),
          _assignTo(),
        ],
      ),
    );
  }

  Padding _sendButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: SizedBox(
        child: SendButton(
          icon: Icons.send,
          iconColor: Colors.white,
          text: 'Send',
          onPressed: nameController.text.isNotEmpty &&
                  surnameController.text.isNotEmpty &&
                  finalDate != null
              ? _submit
              : null,
        ),
      ),
    );
  }

  SizedBox _assignTo() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Assign to: '),
          DropdownMenu(
            width: ScreenSize.screenWidth * .5,
            dropdownMenuEntries: [],
          )
        ],
      ),
    );
  }

  Row _pickDate() {
    return Row(
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
    );
  }
}
