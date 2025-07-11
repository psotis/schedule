import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/providers.dart';

import '../models/custom_errors.dart';

class AddAppointmentRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<AppointMent>? appointment;

  Future<bool> checkForUser({
    required String name,
    required String surname,
    required String userUid,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection(userUid)
          .where('name', isEqualTo: name)
          .where('surname', isEqualTo: surname)
          .get();
      final userExists = querySnapshot.docs.isNotEmpty;
      return userExists;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendAppointments(
    BuildContext context, {
    required String userUid,
    required String surname,
    required Timestamp date,
    required String name,
    String? employee,
    String? position,
    String? owes,
  }) async {
    // final addUserProvider =
    //     Provider.of<AddUserProvider>(context, listen: false);
    try {
      if (await checkForUser(name: name, surname: surname, userUid: userUid) ==
          true) {
        firestore.collection(userUid).add({
          'name': name,
          'surname': surname,
          'phone': '',
          'email': '',
          'address': '',
          'description': [''],
          'amka': '',
          'date': date,
          'position': position ?? '',
          'employee': employee ?? '',
          'owes': '',
        }).then((_) {
          print("collection created");
        }).catchError((error) {
          print("An error occurred: $error");
        });
      } else {
        // ignore: use_build_context_synchronously
        context.read<AddUserProvider>().addUser(
              userUid: userUid,
              surname: surname,
              name: name,
              phone: '',
              email: '',
              address: '',
              description: '',
              amka: '',
              owes: '',
            );
        await Future.delayed(Duration(milliseconds: 500));
        firestore.collection(userUid).add({
          'name': name,
          'surname': surname,
          'phone': '',
          'email': '',
          'address': '',
          'description': [''],
          'amka': '',
          'date': date,
          'position': position ?? '',
          'employee': employee ?? '',
          'owes': '',
        }).then((_) {
          print("collection created");
        }).catchError((error) {
          print("An error occurred: $error");
        });
      }
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }
}
