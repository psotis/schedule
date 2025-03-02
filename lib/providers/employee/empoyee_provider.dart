// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/employee/employee_state.dart';
import 'package:scheldule/repositories/employee_repository.dart';

class EmployeeProvider with ChangeNotifier {
  EmployeeState? _employeeState = EmployeeState.initial();
  EmployeeState? get employeeState => _employeeState;

  List<Employee> employees = [];

  late DocumentReference documentReference;
  late String deleteDoc;
  User? user;

  final EmployeeRepository employeeRepository;
  EmployeeProvider({
    required this.employeeRepository,
  });

  Future<void> addEmployee({
    required String name,
    required String surname,
    required String userUid,
    required String phone,
    required String email,
    required String address,
    required String afm,
    required String amka,
    required String specialization,
    required String contractType,
  }) async {
    _employeeState =
        _employeeState?.copyWith(employeeStatus: EmployeeStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await employeeRepository.addEmployee(
        userUid: userUid,
        surname: surname,
        phone: phone,
        name: name,
        email: email,
        address: address,
        afm: afm,
        amka: amka,
        specialization: specialization,
        contractType: contractType,
      );

      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.loaded);
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 2));
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.send);
      notifyListeners();
      await Future.delayed(Duration(seconds: 2));
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.initial);
      notifyListeners();
    } catch (e) {
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.error);
      notifyListeners();
      throw Exception();
    }
  }

  Future<void> editEmployee({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String afm,
    required String specialization,
    required String contractType,
    required String userUid,
    required String docId,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    _employeeState =
        _employeeState?.copyWith(employeeStatus: EmployeeStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await employeeRepository.editEmployee(
        name: name,
        surname: surname,
        phone: phone,
        email: email,
        address: address,
        description: description,
        amka: amka,
        userUid: userUid,
        afm: afm,
        specialization: specialization,
        contractType: contractType,
        docId: docId,
      );
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.send);
      notifyListeners();
      // await Future.delayed(Duration(milliseconds: 500));
      // _searchUserState = _searchUserState.copyWith(
      //     searchUserStatus: SearchUserStatus.bringEditedUser);
      // notifyListeners();
      await Future.delayed(Duration(seconds: 2));
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.loaded);
      notifyListeners();
    } catch (e) {
      _employeeState =
          _employeeState?.copyWith(employeeStatus: EmployeeStatus.error);
      notifyListeners();
      throw Exception();
    }
  }

  Future<void> deleteEmployee(String userId, String userDoc) async {
    await employeeRepository.removeEmployee(userId: userId, userDoc: userDoc);

    _employeeState =
        _employeeState?.copyWith(employeeStatus: EmployeeStatus.delete);
    notifyListeners();
  }
}
