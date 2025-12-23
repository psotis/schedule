// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/colors.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

class EmployeeCard extends StatefulWidget {
  final Employee employe;
  final User? user;

  const EmployeeCard({
    super.key,
    required this.employe,
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

  final _formKey = GlobalKey<FormState>();

  Color _selectedColor = Colors.lime;

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
    final colorHex = colorToHexs(_selectedColor);

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
          color: colorHex,
        );
  }

  void _removeEmployee(
      {required String employeeId, required String userDoc}) async {
    await context
        .read<EmployeeProvider>()
        .deleteEmployee(employeeId: employeeId, userDoc: userDoc);
  }

  void hideScreen() async {
    context.read<ToggleScreenProvider>().showInitialEmployeeScreen();
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = hexToColors(widget.employe.color) ?? Colors.lime;
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Επέλεξε χρώμα'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              enableAlpha: false,
              displayThumbColor: true,
              portraitOnly: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ακύρωση'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 900,
        child: Center(
          child: Column(
            children: [
              _form(context),
              _buttons(context),
            ],
          ),
        ),
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
            _removeEmployee(
              employeeId: widget.user!.uid,
              userDoc: widget.employe.id,
            );

            hideScreen();
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

            hideScreen();
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
    );
  }

  Padding _form(
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: 30),
      child: SizedBox(
        width: 400,
        height: MediaQuery.of(context).size.height * .8,
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
                SendButton(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.black,
                  text: 'Χρώμα',
                  onPressed: _openColorPicker,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
