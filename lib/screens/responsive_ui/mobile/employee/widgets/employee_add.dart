import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scheldule/providers/employee/employee_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';

import '../../../../../constants/logos/photos_gifs.dart';
import '../../../../../utils/snackbar.dart';

class EmployeeAdd extends StatefulWidget {
  final User? user;
  const EmployeeAdd({super.key, this.user});

  @override
  State<EmployeeAdd> createState() => _EmployeeAddState();
}

class _EmployeeAddState extends State<EmployeeAdd> {
  String? name,
      surname,
      email,
      phone,
      address,
      amka,
      afm,
      specialiazation,
      contractType;
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    nameController = TextEditingController();
    surnameController = TextEditingController();
    phoneController = TextEditingController();
    super.initState();
  }

  Color pickerColor = Colors.transparent;
  Color currentColor = Color(0xff443a49);

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();

    await context.read<EmployeeProvider>().addEmployee(
          userUid: widget.user!.uid,
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          afm: afm!,
          amka: amka!,
          contractType: contractType!,
          specialiazation: specialiazation!,
          color: pickerColor,
        );
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(builder: (context, state, child) {
      if (state.employeeState?.employeeStatus == EmployeeStatus.loading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      if (state.employeeState?.employeeStatus == EmployeeStatus.send) {
        return Center(
          child: Text('Ο εργαζόμενος προστέθηκε'),
        );
      }
      if (state.employeeState?.employeeStatus == EmployeeStatus.error) {
        return Center(
          child: Text('Προσπάθησε ξανά'),
        );
      }

      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _textFields(),
            ),
          ),
        ),
      );
    });
  }

  Column _textFields() {
    return Column(
      spacing: 15,
      children: [
        Row(
          spacing: 20,
          children: [
            Flexible(
              child: CustomTextForm(
                labelText: 'Όνομα',
                hintText: 'John',
                prefixIcon: Icons.person,
                onChanged: (value) {
                  setState(() {
                    nameController.text = value;
                  });
                },
                onSaved: (value) {
                  name = value;
                },
              ),
            ),
            Flexible(
              child: CustomTextForm(
                labelText: 'Επώνυμο',
                hintText: 'Doe',
                prefixIcon: Icons.person_2,
                onChanged: (value) {
                  setState(() {
                    surnameController.text = value;
                  });
                },
                onSaved: (value) {
                  surname = value;
                },
              ),
            ),
          ],
        ),
        Row(
          spacing: 20,
          children: [
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'Email',
                hintText: 'example@gmail.com',
                prefixIcon: Icons.email,
                onSaved: (value) {
                  email = value;
                },
              ),
            ),
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'Τηλέφωνο',
                hintText: '6900000000',
                prefixIcon: Icons.phone,
                onChanged: (value) {
                  setState(() {
                    phoneController.text = value;
                  });
                },
                onSaved: (value) {
                  phone = value;
                },
              ),
            ),
          ],
        ),
        Row(
          spacing: 20,
          children: [
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'Διεύθυνση',
                hintText: 'Agiou Nikolaou, Patra',
                prefixIcon: Icons.home,
                onSaved: (value) {
                  address = value;
                },
              ),
            ),
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'ΑΜΚΑ',
                hintText: '800000000',
                prefixIcon: Icons.numbers,
                onSaved: (value) {
                  amka = value;
                },
              ),
            ),
          ],
        ),
        Row(
          spacing: 20,
          children: [
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'ΑΦΜ',
                hintText: '800000000',
                prefixIcon: Icons.numbers_outlined,
                onSaved: (value) {
                  afm = value;
                },
              ),
            ),
            Flexible(
              flex: 1,
              child: CustomTextForm(
                labelText: 'Τύπος συμβολαίου',
                hintText: 'Πλήρης απασχόλησης',
                prefixIcon: Icons.work_history,
                onSaved: (value) {
                  contractType = value;
                },
              ),
            ),
          ],
        ),
        CustomTextForm(
          labelText: 'Ειδικότητα',
          hintText: 'Κομμωτής',
          prefixIcon: Icons.work,
          onSaved: (value) {
            specialiazation = value;
          },
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //   children: [
        //     ElevatedButton(
        //         onPressed: () {
        //           showDialog(
        //             context: context,
        //             builder: (context) {
        //               return AlertDialog(
        //                 title: const Text('Διάλεξε χρώμα'),
        //                 content: SingleChildScrollView(
        //                   child: BlockPicker(
        //                     pickerColor: currentColor,
        //                     onColorChanged: changeColor,
        //                   ),
        //                 ),
        //                 actions: <Widget>[
        //                   ElevatedButton(
        //                     child: const Text('Got it'),
        //                     onPressed: () {
        //                       setState(() => currentColor = pickerColor);
        //                       Navigator.of(context).pop();
        //                     },
        //                   ),
        //                 ],
        //               );
        //             },
        //           );
        //         },
        //         child: Text('Pick a color')),
        //     CircleAvatar(
        //       backgroundColor: pickerColor,
        //     ),
        //   ],
        // ),
        SizedBox(height: MediaQuery.of(context).size.height * .15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              Media.addCustomer,
              width: 150,
              height: 150,
            ),
            Flexible(child: _sendButton()),
          ],
        ),
      ],
    );
  }

  Padding _sendButton() {
    bool isEnabled = nameController.text.isNotEmpty ||
        surnameController.text.isNotEmpty ||
        phoneController.text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: SizedBox(
        child: GestureDetector(
          onTap: () {
            if (!isEnabled) {
              snackBarDialog(context,
                  color: Colors.blueGrey,
                  message: 'Συμπλήρωσε Όνομα, Επώνυμο, Τηλέφωνο');
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
                      _submit();

                      // nameController.clear();
                      // surnameController.clear();
                      // phoneController.clear();
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
