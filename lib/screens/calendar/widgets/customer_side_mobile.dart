// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/add%20appointment/add_appointment_provider.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/cutom_text.dart';
import 'package:scheldule/utils/search/search.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';
import '../../../../../repositories/search_edit_user_repository.dart';

class CustomerSideMobile extends StatefulWidget {
  final AppointMent customer;
  final AppointMent appointMent;
  final User? user;
  const CustomerSideMobile({
    super.key,
    required this.customer,
    required this.appointMent,
    this.user,
  });

  @override
  State<CustomerSideMobile> createState() => _CustomerSideMobileState();
}

class _CustomerSideMobileState extends State<CustomerSideMobile> {
  String? name,
      surname,
      email,
      phone,
      address,
      description,
      amka,
      owes,
      employee,
      position;
  int? paid;
  int appointmentLength = 0;
  final _formKey = GlobalKey<FormState>();
  final DateTime? date = DateTime.now();
  String? descriptionDate;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  Timestamp? timestampday;
  late final DateTime selectedDateTime = DateTime.now();

  DateTime? finalDate;
  String? formattedTime;

  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  @override
  void initState() {
    seeApp();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible && _scrollController.offset <= 10) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final addProvider = context.read<AddAppointmentProvider>();
    final searchProvider = context.read<SearchUserProvider>();

    setState(() {
      descriptionDate = DateFormat("dd-MM-yyyy HH:mm").format(date!);
    });

    final userForm = _formKey.currentState;

    if (userForm == null || !userForm.validate()) return;
    userForm.save();

    await addProvider.editAppointment(
      context,
      appointmentId: widget.appointMent.id,
      userUid: widget.user!.uid,
      name: name ?? widget.appointMent.name,
      surname: surname ?? widget.appointMent.surname,
      date: timestampday ?? widget.appointMent.date!,
      employee: employee ?? widget.appointMent.employee,
      position: position ?? widget.appointMent.position,
      paid: paid ?? widget.appointMent.paid,
    );

    await Future.delayed(Duration(milliseconds: 200));

    await searchProvider.editUser(
      name: name ?? widget.customer.name,
      surname: surname ?? widget.customer.surname,
      phone: phone ?? widget.customer.phone,
      email: email ?? widget.customer.email,
      address: address ?? widget.customer.address,
      description: (description == null || description!.isEmpty)
          ? ''
          : "$descriptionDate:  $description",
      amka: amka ?? widget.customer.amka,
      owes: owes ?? widget.customer.owes!,
      userUid: widget.user!.uid,
      docId: widget.customer.id,
    );
  }

  void _removeUser({required String userId, required String userDoc}) async {
    await context
        .read<SearchUserProvider>()
        .deleteUsers(userId: userId, userDoc: userDoc);
  }

  void seeApp() async {
    var length = await SearchEditUserRepository().patientAppointmentLength(
      userId: widget.user?.uid ?? '1',
      name: widget.customer.name,
      surename: widget.customer.surname,
    );
    if (mounted) {
      setState(() {
        appointmentLength = length;
      });
    }
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

  void setEmployee(String name, String surename) {
    setState(() {
      employee = '$name $surename';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = (widget.customer.description ?? [])
        .where((desc) => desc.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.1, 0.5, 0.7, 0.9],
          colors: [
            Color(0xFF005448),
            Color(0xFF007a6b),
            Color(0xFF00a190),
            Color(0xFF00c9b7),
          ],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: CustomText(
            text: "${widget.appointMent.name} ${widget.appointMent.surname}",
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFf1b24b),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Συνολικά ραντεβού: "),
                          Text(appointmentLength.toString()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _form(context),
                      const SizedBox(height: 20),
                      _descriptionList(descriptions),
                    ],
                  ),
                ),
              ),
              // FAB/buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: AnimatedOpacity(
                  opacity: _isFabVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(child: _buttons(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _descriptionList(List<String> descriptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        descriptions.isEmpty
            ? Center(
                child: Text('Καμία περιγραφή', style: TextStyle(fontSize: 18)))
            : Center(
                child: Text('Προηγούμενες περιγραφές',
                    style: TextStyle(fontSize: 18)),
              ),
        const SizedBox(height: 10),
        ...descriptions.reversed.map((desc) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(desc),
              ),
            )),
      ],
    );
  }

  Row _buttons(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        SendButton(
          onPressed: () async {
            _removeUser(
              userId: widget.user!.uid,
              userDoc: widget.customer.id,
            );
            Navigator.pop(context);
            snackBarDialog(context,
                color: Colors.red,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} διαγράφθηκε');
          },
          text: 'Διαγραφή',
          backgroundColor: Colors.red,
          icon: Icons.delete,
        ),
        SendButton(
          onPressed: () async {
            _submit();
            Navigator.pop(context);

            snackBarDialog(context,
                color: Colors.orange,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} ανανεώθηκε');
          },
          text: 'Αποστολή',
          icon: Icons.edit,
          backgroundColor: Colors.orange,
        ),
      ],
    );
  }

  Padding _form(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * .65,
        child: Form(
            key: _formKey,
            child: Column(
              spacing: 15,
              children: [
                CustomTextForm(
                  labelText: 'Όνομα',
                  hintText: 'John',
                  prefixIcon: Icons.people,
                  initial: widget.customer.name,
                  readOnly: true,
                  onSaved: (val) {
                    name = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Επώνυμο',
                  hintText: 'Doe',
                  prefixIcon: Icons.people_alt,
                  initial: widget.customer.surname,
                  readOnly: true,
                  onSaved: (val) {
                    surname = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΜΚΑ',
                  hintText: '800000000',
                  prefixIcon: Icons.numbers,
                  initial: widget.customer.amka,
                  onSaved: (val) {
                    amka = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τηλέφωνο',
                  hintText: '6900000000',
                  prefixIcon: Icons.phone,
                  readOnly: true,
                  initial: widget.customer.phone,
                  onSaved: (val) {
                    phone = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Θέση',
                  hintText: 'Γραφείο/Καρέκλα/Δωμάτειο',
                  prefixIcon: Icons.numbers,
                  initial: widget.appointMent.position,
                  onSaved: (val) {
                    position = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Υπάλληλος',
                  hintText: 'John Doe',
                  prefixIcon: Icons.person,
                  readOnly: true,
                  initial: widget.appointMent.employee,
                ),
                Search(
                  user: widget.user,
                  width: ScreenSize.screenWidth * .75,
                  selectSearch: SelectSearch.employee,
                  setAppointment: (p0, p1) => setEmployee(p0, p1),
                ),
                CustomTextForm(
                  labelText: 'Οφειλή',
                  hintText: 'Υπόλοιπο',
                  prefixIcon: Icons.euro,
                  chooseText: ChooseText.owes,
                  initial: widget.customer.owes,
                  onSaved: (val) {
                    owes = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Ραντεβού',
                  hintText: '6900000000',
                  prefixIcon: Icons.calendar_month,
                  readOnly: true,
                  initial: DateFormat('dd-MM-yyyy HH:mm')
                      .format(widget.appointMent.date!.toDate()),
                ),
                CustomTextForm(
                  labelText: 'Πληρωμή',
                  hintText: 'Σημερινό πληρωτέο ποσό',
                  prefixIcon: Icons.euro,
                  chooseText: ChooseText.owes,
                  initial: widget.appointMent.paid.toString(),
                  onSaved: (val) {
                    paid = int.tryParse(val!);
                  },
                ),
                CustomTextForm(
                  labelText: 'Περιγραφή',
                  hintText: '...........',
                  prefixIcon: Icons.description,
                  // initial: widget.customer.description,
                  onSaved: (val) {
                    description = val;
                  },
                ),
                _pickDate()
              ],
            )),
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
