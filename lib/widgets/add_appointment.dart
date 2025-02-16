// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';
import 'package:scheldule/providers/add%20appointment/add_appointment_status.dart';
import 'package:scheldule/screens/homepage/widgets/calendar_widget.dart';

import '../providers/providers.dart';
import '../providers/search user/search_user_status.dart';

class AddAppointment extends StatefulWidget {
  final User? user;
  AddAppointment({
    super.key,
    this.user,
  });

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  String? name, surname, email, phone, address, description;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController controller = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  DateTime? finalDate;

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

  void addAppointment({
    required String userId,
    required DateTime selectedDay,
    required DateTime endOfDay,
  }) async {
    await Future.delayed(Duration(), () {
      context
          .read<AppointmentProvider>()
          .getAppointMents(userId, selectedDay, endOfDay);
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
      print(finalDate);
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

  var selectedUser;

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10),
        SizedBox(
          height: ScreenSize.screenHeight * .10,
          width: ScreenSize.screenWidth * .18,
          child: Consumer<SearchUserProvider>(
            builder: (context, value, child) {
              if (value.searchUserState.searchUserStatus ==
                  SearchUserStatus.empty) {
                return Center(child: Text('Καταχώρησε ασθενή πρώτα'));
              }
              if (value.searchUserState.searchUserStatus ==
                  SearchUserStatus.loadedList) {
                return ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    var p = value.appointment[index];
                    print('This is the docId of search ${p.id}');
                    return DropdownMenu(
                      menuHeight: ScreenSize.screenHeight * .4,
                      width: ScreenSize.screenWidth * .20,
                      inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                      textStyle: TextStyle(fontSize: 14),
                      label: Text('Αναζήτηση για ραντεβού',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                      enableFilter: true,
                      enableSearch: true,
                      dropdownMenuEntries: value.appointment.map((e) {
                        return DropdownMenuEntry(
                            value: e, label: '${e.name} ${e.surname}');
                      }).toList(),
                      onSelected: (val) {
                        setState(() {
                          selectedUser = val;
                          nameController.text = val!.name;
                          surnameController.text = val.surname;
                        });
                      },
                    );
                  },
                );
              }
              return SizedBox();
            },
          ),
        ),
        Consumer<AddAppointmentProvider>(builder: (context, state, child) {
          if (state.appointmentState.appointmentStatus ==
              AddAppointmentStatus.loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state.appointmentState.appointmentStatus ==
              AddAppointmentStatus.loaded) {
            return Center(
              child: Text('Ραντεβού προστέθηκε'),
            );
          }
          if (state.appointmentState.appointmentStatus ==
              AddAppointmentStatus.error) {
            return Center(
              child: Text('Αποτυχία'),
            );
          }
          if (state.appointmentState.appointmentStatus ==
              AddAppointmentStatus.addAppointment) {
            addAppointment(
              userId: widget.user!.uid,
              selectedDay: selectedDay1,
              endOfDay: endOfDay,
            );
            nameController.clear();
            surnameController.clear();

            print(finalDate);
          }
          finalDate == null;
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      hintText: 'Όνομα',
                      label: Text('Όνομα'),
                    ),
                    onChanged: (value) {
                      setState(() {
                        value = nameController.text;
                      });
                    },
                    onSaved: (newValue) {
                      name = newValue;
                    },
                  ),
                  SizedBox(height: 10),
                  // DateTimePicker(),
                  TextFormField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      hintText: 'Επώνυμο',
                      label: Text('Επώνυμο'),
                    ),
                    onChanged: (value) {
                      setState(() {
                        value = surnameController.text;
                      });
                    },
                    onSaved: (newValue) {
                      surname = newValue;
                    },
                  ),

                  SizedBox(height: 20),
                  SizedBox(
                    width: ScreenSize.screenWidth,
                    child: ElevatedButton(
                      style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                          backgroundColor: WidgetStatePropertyAll(
                              Color.fromARGB(255, 226, 48, 24))),
                      onPressed: () async => pickDateTime(),
                      child: finalDate == null
                          ? Text('Διάλεξε ημερομηνία')
                          : Text(finalDate.toString()),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                      // height: 10,
                      width: ScreenSize.screenWidth,
                      child: ElevatedButton(
                          onPressed: nameController.text.isNotEmpty &&
                                  surnameController.text.isNotEmpty &&
                                  finalDate != null
                              ? _submit
                              : null,
                          child: Text('Προσθήκη ραντεβού')))
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
