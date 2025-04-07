import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_user_status.dart';

class AddUserProvider extends ChangeNotifier {
  AddUserState _addUserState = AddUserState.initial();
  AddUserState get addUserState => _addUserState;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addUser({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String owes,
    required String userUid,
  }) async {
    _addUserState =
        _addUserState.copyWith(addUserStatus: AddUserStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      FirebaseFirestore.instance.collection(userUid).add({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'description': [description],
        'amka': amka,
        'owes': owes,
        'date': Timestamp.fromMicrosecondsSinceEpoch(0),
      }).then((DocumentReference doc) {
        print(doc.id);
        print("collection created");
      }).catchError((error) {
        print("An error occurred: $error");
      });

      _addUserState = _addUserState.copyWith(addUserStatus: AddUserStatus.sent);
      notifyListeners();
      await Future.delayed(Duration(seconds: 1));
      _addUserState =
          _addUserState.copyWith(addUserStatus: AddUserStatus.bringUser);
      notifyListeners();

      await Future.delayed(Duration(seconds: 3));
      _addUserState =
          _addUserState.copyWith(addUserStatus: AddUserStatus.initial);
      notifyListeners();
    } catch (e) {
      _addUserState =
          _addUserState.copyWith(addUserStatus: AddUserStatus.error);
      notifyListeners();
    }
  }
}
