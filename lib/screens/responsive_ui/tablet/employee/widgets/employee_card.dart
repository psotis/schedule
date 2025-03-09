// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/get%20layout/get_layout.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../utils/cutom_text.dart';

class EmployeeCard extends StatefulWidget {
  final Employee employe;
  final User? user;
  final String title;
  const EmployeeCard({
    super.key,
    required this.employe,
    required this.title,
    this.user,
  });

  @override
  State<EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<EmployeeCard> {
  String? name,
      surname,
      email,
      phone,
      address,
      afm,
      amka,
      specialiazation,
      contractType;
  int appointmentLength = 0;
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

    context.read<EmployeeProvider>().editEmployee(
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          afm: afm!,
          amka: amka!,
          specialiazation: specialiazation!,
          contractType: contractType!,
          userUid: widget.user!.uid,
          docId: widget.employe.id,
        );
  }

  void _removeEmployee(
      {required String employeeId, required String userDoc}) async {
    await context
        .read<EmployeeProvider>()
        .deleteEmployee(employeeId: employeeId, userDoc: userDoc);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var layoutWidth = getLayout(context);

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
              _form(context, layoutWidth),
            ],
          ),
        ),
        floatingActionButton: _buttons(context),
      ),
    );
  }

  Padding _buttons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 20,
        children: [
          SendButton(
            onPressed: () {
              _removeEmployee(
                employeeId: widget.user!.uid,
                userDoc: widget.employe.id,
              );

              Navigator.pop(context);
              snackBarDialog(context,
                  color: Colors.red,
                  message:
                      'Ο εργαζόμενος ${widget.employe.name} ${widget.employe.surname} διαγράφθηκε');
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
                      'Ο εργαζόμενος ${widget.employe.name} ${widget.employe.surname} ανανεώθηκε');
            },
            text: 'Αποστολή',
            icon: Icons.edit,
            backgroundColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Padding _form(BuildContext context, double layoutWidth) {
    return Padding(
      padding: EdgeInsets.only(top: 30),
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
              spacing: 20,
              children: [
                CustomTextForm(
                  labelText: 'Όνομα',
                  hintText: 'John',
                  prefixIcon: Icons.people,
                  initial: widget.employe.name,
                  onSaved: (val) {
                    name = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Επώνυμο',
                  hintText: 'Doe',
                  prefixIcon: Icons.people_alt,
                  initial: widget.employe.surname,
                  onSaved: (val) {
                    surname = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Emal',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icons.email,
                  initial: widget.employe.email,
                  onSaved: (val) {
                    email = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τηλέφωνο',
                  hintText: '6900000000',
                  prefixIcon: Icons.phone,
                  initial: widget.employe.phone,
                  onSaved: (val) {
                    phone = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Διεύθυνση',
                  hintText: 'Agiou Nikolaou, Patra',
                  prefixIcon: Icons.home,
                  initial: widget.employe.address,
                  onSaved: (val) {
                    address = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΜΚΑ',
                  hintText: '800000000',
                  prefixIcon: Icons.numbers,
                  initial: widget.employe.address,
                  onSaved: (val) {
                    amka = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΦΜ',
                  hintText: '800000000',
                  prefixIcon: Icons.description,
                  initial: widget.employe.afm,
                  onSaved: (val) {
                    afm = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τύπος συμβολαίου',
                  hintText: 'Πλήρης απασχόλησης',
                  prefixIcon: Icons.work_history,
                  initial: widget.employe.contractType,
                  onSaved: (value) {
                    contractType = value;
                  },
                ),
                CustomTextForm(
                  labelText: 'Ειδικότητα',
                  hintText: 'Κομμωτής',
                  prefixIcon: Icons.work,
                  initial: widget.employe.specialiazation,
                  onSaved: (value) {
                    specialiazation = value;
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
