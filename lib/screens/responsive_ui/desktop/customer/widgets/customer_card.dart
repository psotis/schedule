// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

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
          description: description!.isEmpty
              ? description!
              : "$descriptionDate:  $description",
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = (widget.customer.description ?? [])
        .where((desc) => desc.trim().isNotEmpty)
        .toList();

    return Material(
      color: Colors.transparent,
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
