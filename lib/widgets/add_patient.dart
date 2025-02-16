// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';

import '../providers/add user/add_user_status.dart';
import '../providers/providers.dart';

// ignore: must_be_immutable
class AddPatient extends StatefulWidget {
  User? user;
  AddPatient({
    super.key,
    this.user,
  });

  @override
  State<AddPatient> createState() => _AddPatientState();
}

class _AddPatientState extends State<AddPatient> {
  String? name, surname, email, phone, address, description, amka;
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateUser = AutovalidateMode.disabled;
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
        _autovalidateUser = AutovalidateMode.always;
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
    ScreenSize().init(context);
    return Consumer<AddUserProvider>(builder: (context, state, child) {
      if (state.addUserState.addUserStatus == AddUserStatus.loading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      if (state.addUserState.addUserStatus == AddUserStatus.sent) {
        return Center(
          child: Text('User was added'),
        );
      }
      if (state.addUserState.addUserStatus == AddUserStatus.error) {
        return Center(
          child: Text('Something happened try again'),
        );
      }
      if (state.addUserState.addUserStatus == AddUserStatus.bringUser) {
        context.read<SearchUserProvider>().searchUsers(user: widget.user!.uid);
      }
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
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  hintText: 'Email',
                  label: Text('Email'),
                ),
                onSaved: (newValue) {
                  email = newValue;
                },
                // validator: (String? value) {
                //   if (value == null || value.trim().isEmpty) {
                //     return 'Προσθηκη εμαιλ';
                //   }
                //   if (!isEmail(value.trim())) {
                //     return 'Κακη γραφη εμαιλ';
                //   }
                //   return null;
                // },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  hintText: 'Τηλέφωνο',
                  label: Text('Τηλέφωνο'),
                ),
                onChanged: (value) {
                  setState(() {
                    value = phoneController.text;
                  });
                },
                onSaved: (newValue) {
                  phone = newValue;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  hintText: 'Διεύθυνση',
                  label: Text('Διεύθυνση'),
                ),
                onSaved: (newValue) {
                  address = newValue;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  hintText: 'ΑΜΚΑ',
                  label: Text('ΑΜΚΑ'),
                ),
                onSaved: (newValue) {
                  amka = newValue;
                },
              ),
              SizedBox(height: 10),
              Expanded(
                child: TextFormField(
                  maxLines: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    hintText: 'Περιγραφή',
                    label: Text('Περιγραφή'),
                  ),
                  onSaved: (newValue) {
                    description = newValue;
                  },
                ),
              ),
              // SizedBox(height: 10),
              SizedBox(
                  // height: 10,
                  width: ScreenSize.screenWidth,
                  child: ElevatedButton(
                      onPressed: nameController.text.isEmpty ||
                              surnameController.text.isEmpty ||
                              phoneController.text.isEmpty
                          ? null
                          : () {
                              _submit();
                              nameController.clear();
                              surnameController.clear();
                              phoneController.clear();
                            },
                      child: Text('Προσθήκη ασθενή')))
            ],
          ),
        ),
      );
    });
  }
}
