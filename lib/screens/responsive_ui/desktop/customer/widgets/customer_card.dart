// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';

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
  String? name, surname, email, phone, address, description, amka;
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

    await context.read<SearchUserProvider>().editUser(
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          description: description!,
          amka: amka!,
          userUid: widget.user!.uid,
          docId: widget.customer.id,
        );
  }

  void _removeUser({required String userId, required String userDoc}) async {
    await context
        .read<SearchUserProvider>()
        .deleteUsers(userId: userId, userDoc: userDoc);
  }

  void hideScreen() async {
    context.read<ToggleScreenProvider>().showInitialScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 800,
        child: Center(
          child: Column(
            children: [
              _form(context),
              // Spacer(),
              _buttons(context),
            ],
          ),
        ),
      ),
    );
  }

  Padding _buttons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
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
                      'User ${widget.customer.name} ${widget.customer.surname} was deleted');
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
                      'User ${widget.customer.name} ${widget.customer.surname} was edited');
            },
            text: 'Αποστολή',
            icon: Icons.edit,
            backgroundColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Padding _form(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30),
      child: SizedBox(
        width: 400,
        height: MediaQuery.of(context).size.height * .7,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
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
                  labelText: 'Περιγραφή',
                  hintText: '...........',
                  prefixIcon: Icons.description,
                  initial: widget.customer.description,
                  onSaved: (val) {
                    description = val;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
