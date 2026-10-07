import 'package:flutter/material.dart';

import '../../repositories/search_edit_user_repository.dart';

import 'add_user_status.dart';

class AddUserProvider extends ChangeNotifier {
  final SearchEditUserRepository repository;

  AddUserProvider({required this.repository});

  AddUserState _addUserState = AddUserState.initial();
  AddUserState get addUserState => _addUserState;

  Future<void> addUser({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String owes,
    int? paid,
  }) async {
    _addUserState =
        _addUserState.copyWith(addUserStatus: AddUserStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await repository.addPatient(
        name: name,
        surname: surname,
        phone: phone,
        email: email,
        address: address,
        description: description,
        amka: amka,
        owes: owes,
      );

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
