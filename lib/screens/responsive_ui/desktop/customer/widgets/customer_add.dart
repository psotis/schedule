import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';

import '../../../../../constants/logos/photos_gifs.dart';
import '../../../../../providers/add user/add_user_status.dart';
import '../../../../../utils/snackbar.dart';

class CustomerAdd extends StatefulWidget {
  final User? user;
  const CustomerAdd({super.key, this.user});

  @override
  State<CustomerAdd> createState() => _CustomerAddState();
}

class _CustomerAddState extends State<CustomerAdd> {
  String? name, surname, email, phone, address, description, amka;
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

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();
    await context.read<AddUserProvider>().addUser(
          userUid: widget.user!.uid,
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          description: description!,
          amka: amka!,
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
    return Consumer<AddUserProvider>(builder: (context, state, child) {
      if (state.addUserState.addUserStatus == AddUserStatus.loading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      if (state.addUserState.addUserStatus == AddUserStatus.sent) {
        return Center(
          child: Text('Ο πελάτης προστέθηκε'),
        );
      }
      if (state.addUserState.addUserStatus == AddUserStatus.error) {
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
              flex: 2,
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
              flex: 2,
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
        CustomTextForm(
          labelText: 'Περιγραφή',
          hintText: '...........',
          prefixIcon: Icons.description,
          onSaved: (value) {
            description = value;
          },
        ),
        SizedBox(height: MediaQuery.of(context).size.height * .15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              Media.addCustomer,
              width: 200,
              height: 200,
            ),
            _sendButton(),
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
