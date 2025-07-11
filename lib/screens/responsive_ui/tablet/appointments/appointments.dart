// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/logos/photos_gifs.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';
import 'package:scheldule/providers/providers.dart';

import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../providers/add appointment/add_appointment_provider.dart';
import '../../../../utils/custom_text_form.dart';
import '../../../../utils/search/search.dart';

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
  String? name, surname, employee, position;

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController positionController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  late Timestamp timestampday;

  DateTime? finalDate;
  String? formattedTime;

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  void _submit(BuildContext context) async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();
    await context.read<AddAppointmentProvider>().addAppointment(
          context,
          userUid: widget.user!.uid,
          name: name!,
          surname: surname!,
          date: timestampday,
          employee: employee,
          position: position,
        );
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
      initialEntryMode: TimePickerEntryMode.dialOnly,
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
    positionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    positionController.dispose();
    super.dispose();
  }

  void setCustomer(String name, String surename) {
    setState(() {
      nameController.text = name;
      surnameController.text = surename;
    });
  }

  void setEmployee(String name, String surename) {
    setState(() {
      employee = '$name $surename';
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Padding(
      padding: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            SizedBox(height: 15),
            Search(
              user: widget.user,
              width: ScreenSize.screenWidth * .3,
              selectSearch: SelectSearch.customer,
              setAppointment: (p0, p1) => setCustomer(p0, p1),
            ),
            _form(),
            SizedBox(height: MediaQuery.of(context).size.height * .15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(
                  Media.addAppointment,
                  width: 150,
                  height: 150,
                ),
                _sendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Form _form() {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 20,
        children: [
          SizedBox(
            width: ScreenSize.screenWidth * .5,
            child: CustomTextForm(
              controller: nameController,
              labelText: 'Όνομα',
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
          ),
          SizedBox(
            width: ScreenSize.screenWidth * .5,
            child: CustomTextForm(
              controller: surnameController,
              labelText: 'Επώνυμο',
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
          ),
          _pickDate(),
          _assignTo(),
          _position(),
        ],
      ),
    );
  }

  SizedBox _position() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        spacing: 50,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Θέση:'),
          SizedBox(
            width: 250,
            child: CustomTextForm(
              controller: positionController,
              labelText: 'Θέση',
              hintText: 'Γραφείο/Καρέκλα/Δωμάτιο',
              prefixIcon: Icons.room,
              onChanged: (value) {
                setState(() {
                  positionController.text == value;
                });
              },
              onSaved: (value) {
                position = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Padding _sendButton() {
    bool isEnabled = nameController.text.isNotEmpty &&
        surnameController.text.isNotEmpty &&
        finalDate != null;
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: SizedBox(
        child: GestureDetector(
          onTap: () {
            if (!isEnabled) {
              snackBarDialog(context,
                  color: Colors.blueGrey,
                  message: 'Συμπλήρωσε Όνομα, Επώνυμο, Ημερομηνία');
            }
          },
          child: AbsorbPointer(
            absorbing: !isEnabled,
            child: SendButton(
              icon: Icons.send,
              iconColor: Colors.white,
              text: 'Αποστολή',
              backgroundColor: Color(0xFF003128),
              onPressed: isEnabled
                  ? () {
                      _submit(context);
                      nameController.clear();
                      surnameController.clear();
                      positionController.clear();
                      formattedTime = null;
                      snackBarDialog(context,
                          color: Colors.blueGrey, message: 'Επιτυχής αποστολή');
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _assignTo() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        spacing: 50,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ανάθεση σε: '),
          Search(
            user: widget.user,
            width: ScreenSize.screenWidth * .3,
            selectSearch: SelectSearch.employee,
            setAppointment: (p0, p1) => setEmployee(p0, p1),
          ),
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
        Text('Διάλεξε ημερομηνία'),
        OutlinedButton(
            onPressed: pickDateTime,
            child: formattedTime == null
                ? Icon(Icons.date_range)
                : Text(formattedTime!)),
      ],
    );
  }
}
