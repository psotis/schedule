// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';
import '../../../../../repositories/search_edit_user_repository.dart';

class CustomerCard extends StatefulWidget {
  final AppointMent customer;
  final User? user;
  const CustomerCard({
    super.key,
    required this.customer,
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

  @override
  void initState() {
    seeApp();
    super.initState();
  }

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

    await context.read<SearchUserProvider>().editUser(
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

  void hideScreen() async {
    context.read<ToggleScreenProvider>().showInitialScreen();
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = (widget.customer.description ?? [])
        .where((desc) => desc.trim().isNotEmpty)
        .toList();
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Stack(
          children: [
            Column(
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
                _form(context),
                _descriptionList(descriptions),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: _buttons(context)),
            ),
          ],
        ),
      ),
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

            hideScreen();
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
            hideScreen();

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
      padding: EdgeInsets.only(top: 20),
      child: SizedBox(
        width: 400,
        height: MediaQuery.of(context).size.height * .65,
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
            ],
          ),
        ),
      ),
    );
  }
}
