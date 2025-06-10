// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/models/custom_errors.dart';

import 'package:scheldule/repositories/search_edit_user_repository.dart';

import '../../models/appointment_model.dart';
import 'search_user_status.dart';

class SearchUserProvider extends ChangeNotifier {
  SearchUserState _searchUserState = SearchUserState.initial();
  SearchUserState get searchUserState => _searchUserState;
  List<AppointMent> appointment = [];
  AppointMent? searchPatient;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;
  late int length;

  final SearchEditUserRepository searchEditUserRepository;
  SearchUserProvider({
    required this.searchEditUserRepository,
  });

  Future<List<AppointMent>> searchUsers({required String user}) async {
    _searchUserState =
        _searchUserState.copyWith(searchUserStatus: SearchUserStatus.loading);
    notifyListeners();
    try {
      appointment = await searchEditUserRepository.findUsers(user: user);
      if (appointment.isEmpty) {
        _searchUserState = _searchUserState.copyWith(
            appointMent: [], searchUserStatus: SearchUserStatus.empty);
        notifyListeners();
      } else {
        _searchUserState = _searchUserState.copyWith(
            appointMent: appointment,
            searchUserStatus: SearchUserStatus.loadedList);
        notifyListeners();
      }

      return appointment;
    } on CustomError catch (e) {
      print(e);
      rethrow;
    }
  }

  // Future<int> getLength() async {
  //   length = await searchEditUserRepository.patientAppointmentLength(
  //       userId: userId, name: name, surename: surename);
  // }

  //! ******** This is for search user to add for appointment **********
  // Future<AppointMent> searchPatients(
  //     {required String userUid,
  //     required String name,
  //     required String surname}) async {
  //   try {
  //     final AppointMent searchPatient = await searchEditUserRepository.seeUser(
  //         userUid: userUid, name: name, surname: surname);
  //     print(searchPatient);
  //     return searchPatient;
  //   } catch (e) {
  //     throw Exception();
  //   }
  // }

  Future<void> editUser({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String userUid,
    required String docId,
    required String owes,
    bool? heart,
    bool? breathe,
    bool? sugar,
    bool? ypertash,
    bool? neuro,
    bool? orthopedic,
    bool? selfCare,
    bool? helpCare,
    bool? disabled,
    bool? good,
    bool? medium,
    bool? bad,
    bool? yes,
    bool? no,
    String? birthday,
    String? allo,
    String? startingDate,
    String? mainIssue,
    String? doctor,
    String? surgeryPast,
    String? surgeryNow,
    String? pharmacy,
    String? allergies,
    String? spot,
    String? missFunctions,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    _searchUserState =
        _searchUserState.copyWith(searchUserStatus: SearchUserStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await searchEditUserRepository.editPatient(
          name: name,
          surname: surname,
          phone: phone,
          email: email,
          address: address,
          description: description,
          amka: amka,
          owes: owes,
          // Additional fields
          heart: heart,
          breathe: breathe,
          sugar: sugar,
          ypertash: ypertash,
          neuro: neuro,
          orthopedic: orthopedic,
          selfCare: selfCare,
          helpCare: helpCare,
          disabled: disabled,
          good: good,
          medium: medium,
          bad: bad,
          yes: yes,
          no: no,
          birthday: birthday,
          allo: allo,
          startingDate: startingDate,
          mainIssue: mainIssue,
          doctor: doctor,
          surgeryPast: surgeryPast,
          surgeryNow: surgeryNow,
          pharmacy: pharmacy,
          allergies: allergies,
          spot: spot,
          missFunctions: missFunctions,
          userUid: userUid,
          docId: docId);
      _searchUserState =
          _searchUserState.copyWith(searchUserStatus: SearchUserStatus.sent);
      notifyListeners();
      // await Future.delayed(Duration(milliseconds: 500));
      // _searchUserState = _searchUserState.copyWith(
      //     searchUserStatus: SearchUserStatus.bringEditedUser);
      // notifyListeners();
      await Future.delayed(Duration(seconds: 2));
      _searchUserState = _searchUserState.copyWith(
          searchUserStatus: SearchUserStatus.loadedList);
      notifyListeners();
    } catch (e) {
      _searchUserState =
          _searchUserState.copyWith(searchUserStatus: SearchUserStatus.error);
      notifyListeners();
      throw Exception();
    }
  }

  Future<void> deleteUsers(
      {required String userId, required String userDoc}) async {
    try {
      await searchEditUserRepository.deleteUsers(
          userId: userId, userDoc: userDoc);
      _searchUserState =
          _searchUserState.copyWith(searchUserStatus: SearchUserStatus.delete);
      notifyListeners();
    } on CustomError catch (e) {
      _searchUserState = _searchUserState.copyWith(
          searchUserStatus: SearchUserStatus.error, error: e);
      notifyListeners();
      rethrow;
    }
  }
}
