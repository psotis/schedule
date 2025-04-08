// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/get%20layout/get_layout.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';
import '../../../../../repositories/search_edit_user_repository.dart';
import '../../../../../utils/cutom_text.dart';

class CustomerCard extends StatefulWidget {
  final AppointMent customer;
  final User? user;
  final String title;
  const CustomerCard({
    super.key,
    required this.customer,
    required this.title,
    this.user,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  String? name, surname, email, phone, address, description, amka, owes;
  int appointmentLength = 0;
  final _formKey = GlobalKey<FormState>();
  final DateTime? date = DateTime.now();
  String? descriptionDate;

  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    setState(() {
      descriptionDate = DateFormat("dd-MM-yyyy HH:mm").format(date!);
    });

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();

    context.read<SearchUserProvider>().editUser(
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          description: "$descriptionDate:  $description",
          amka: amka!,
          owes: owes!,
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
      userId: widget.user!.uid,
      name: widget.customer.name,
      surename: widget.customer.surname,
    );
    setState(() {
      appointmentLength = length;
    });
  }

  @override
  void initState() {
    seeApp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var layoutWidth = getLayout(context);
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
            text: widget.title,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFf1b24b),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Συνολικά ραντεβού:"),
                  Text(appointmentLength.toString()),
                ],
              ),
              _form(context, layoutWidth),
              SizedBox(height: 15),
              _descriptionList(descriptions),
            ],
          ),
        ),
        floatingActionButton: _buttons(context),
      ),
    );
  }

  Row _buttons(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        SendButton(
          onPressed: () {
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
          onPressed: () {
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

  Flexible _descriptionList(List<String> descriptions) {
    return Flexible(
        child: SingleChildScrollView(
      child: Column(
        children: [
          descriptions.isEmpty
              ? Text('Καμία περιγραφή', style: TextStyle(fontSize: 18))
              : Text('Προηγούμενες περιγραφές', style: TextStyle(fontSize: 18)),
          ListView.builder(
            shrinkWrap: true,
            reverse: true,
            itemCount: descriptions.length,
            itemBuilder: (BuildContext context, int index) {
              if (descriptions.isEmpty) {
                return SizedBox();
              }
              final desc = descriptions[index];
              return Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                      margin: EdgeInsets.only(right: 10, left: 10, top: 10),
                      child: Padding(
                          padding: EdgeInsets.only(
                              left: 20, top: 10, bottom: 10, right: 20),
                          child: Text(desc.toString()))),
                ),
              );
            },
          ),
        ],
      ),
    ));
  }

  Padding _form(BuildContext context, double layoutWidth) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: SizedBox(
        width: layoutWidth < 600
            ? 350
            : layoutWidth < 1300
                ? 500
                : 700,
        // width: MediaQuery.of(context).size.width * .7,
        // height: MediaQuery.of(context).size.height * .7,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              spacing: 15,
              children: [
                CustomTextForm(
                  labelText: 'Όνομα',
                  hintText: 'John',
                  prefixIcon: Icons.people,
                  initial: widget.customer.name,
                  onSaved: (val) {
                    name = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Επώνυμο',
                  hintText: 'Doe',
                  prefixIcon: Icons.people_alt,
                  initial: widget.customer.surname,
                  onSaved: (val) {
                    surname = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Emal',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icons.email,
                  initial: widget.customer.email,
                  onSaved: (val) {
                    email = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τηλέφωνο',
                  hintText: '6900000000',
                  prefixIcon: Icons.phone,
                  initial: widget.customer.phone,
                  onSaved: (val) {
                    phone = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Διεύθυνση',
                  hintText: 'Agiou Nikolaou, Patra',
                  prefixIcon: Icons.home,
                  initial: widget.customer.address,
                  onSaved: (val) {
                    address = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΜΚΑ',
                  hintText: '800000000',
                  prefixIcon: Icons.numbers,
                  initial: widget.customer.address,
                  onSaved: (val) {
                    amka = val;
                  },
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
                  labelText: 'Περιγραφή',
                  hintText: '...........',
                  prefixIcon: Icons.description,
                  // initial: widget.customer.description,
                  onSaved: (val) {
                    description = val;
                  },
                ),
                // Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
