// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/screen%20sizes/screen_sizes.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../providers/providers.dart';
import '../providers/search user/search_user_status.dart';
import '../repositories/search_edit_user_repository.dart';

// ignore: must_be_immutable
class SeeEditUser extends StatefulWidget {
  AppointMent? list;
  User? user;
  SeeEditUser({
    super.key,
    required this.list,
    this.user,
  });

  @override
  State<SeeEditUser> createState() => _SeeEditUserState();
}

class _SeeEditUserState extends State<SeeEditUser> {
  String? name, surname, email, phone, address, description, amka;
  final _formKey = GlobalKey<FormState>();
  int length = 0;
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
    print(name);

    print(widget.user?.uid);

    context.read<SearchUserProvider>().editUser(
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          description: description!,
          amka: amka!,
          userUid: widget.user!.uid,
          docId: widget.list!.id,
        );
  }

  void fetchEditedOrRemovedUser({required String userId}) async {
    await context
        .read<SearchUserProvider>()
        .searchUsers(user: widget.user!.uid);
  }

  void _removeUser({required String userId, required String userDoc}) async {
    await context
        .read<SearchUserProvider>()
        .deleteUsers(userId: userId, userDoc: userDoc);
  }

  @override
  void initState() {
    super.initState();
    getPatientAppointmentLength();
  }

  void getPatientAppointmentLength() async {
    var fetchedLength =
        await SearchEditUserRepository().patientAppointmentLength(
      userId: widget.user!.uid,
      name: widget.list!.name,
      surename: widget.list!.surname,
    );
    setState(() {
      length = fetchedLength;
    });
    print(length);
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Container(
      height: ScreenSize.screenHeight,
      width: ScreenSize.screenWidth * .5,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<SearchUserProvider>(builder: (_, state, child) {
          if (state.searchUserState.searchUserStatus ==
              SearchUserStatus.loading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.searchUserState.searchUserStatus == SearchUserStatus.sent) {
            return Center(
                child: Text(
              'User updated',
              style: TextStyle(color: Colors.black),
            ));
          }
          if (state.searchUserState.searchUserStatus ==
              SearchUserStatus.error) {
            return Center(
                child: Text('Something went wrong, try again',
                    style: TextStyle(color: Colors.black)));
          }
          if (state.searchUserState.searchUserStatus ==
                  SearchUserStatus.bringEditedUser ||
              state.searchUserState.searchUserStatus ==
                  SearchUserStatus.delete) {
            fetchEditedOrRemovedUser(userId: widget.user!.uid);
          }

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Συνολικά ραντεβού ασθενή: ${length.toString()}',
                          style: TextStyle(color: Colors.black)),
                      IconButton(
                          onPressed: () async {
                            _removeUser(
                                userId: widget.user!.uid,
                                userDoc: widget.list!.id);
                            await Future.delayed(Duration(milliseconds: 500));
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          )),
                    ],
                  ),

                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('Όνομα',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.name,
                      onSaved: (newValue) {
                        name = newValue;
                      },
                    ),
                  ),

                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('Επώνυμο',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.surname,
                      onSaved: (newValue) {
                        surname = newValue;
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('Τηλέφωνο',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.phone,
                      onSaved: (newValue) {
                        phone = newValue;
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('E-mail',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.email,
                      onSaved: (newValue) {
                        email = newValue;
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('Διεύθυνση',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.address,
                      onSaved: (newValue) {
                        address = newValue;
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.screenHeight * .02),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    child: TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text('ΑΜΚΑ',
                              style: TextStyle(color: Colors.black))),
                      initialValue: widget.list!.amka,
                      onSaved: (newValue) {
                        amka = newValue;
                      },
                    ),
                  ),
                  SizedBox(height: ScreenSize.screenHeight * .02),
                  Expanded(
                      flex: 1,
                      child: TextFormField(
                        style: TextStyle(color: Colors.black),
                        maxLines: null,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            label: Text('Περιγραφή',
                                style: TextStyle(color: Colors.black))),
                        initialValue: widget.list!.description,
                        onSaved: (newValue) {
                          description = newValue;
                        },
                      )),
                  // SizedBox(height: ScreenSize.screenHeight * .02),

                  ElevatedButton(
                      onPressed: () async {
                        _submit();
                        await Future.delayed(Duration(seconds: 3));
                        Navigator.pop(context);
                      },
                      child: Text('Αποστολή'))
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
