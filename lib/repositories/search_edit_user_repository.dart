import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/custom_errors.dart';

class SearchEditUserRepository {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;
  QuerySnapshot<Map<String, dynamic>>? appointLength;
  List<AppointMent> appointment = [];
  List<AppointMent> patientLength = [];
  AppointMent? appointMent;

  Future<List<AppointMent>> findUsers({required String user}) async {
    try {
      appointMentsFromFirebase = await firestore
          .collection(user)
          .where('date', isEqualTo: Timestamp.fromMicrosecondsSinceEpoch(0))
          .get();

      appointment = appointMentsFromFirebase!.docs
          .map((e) => AppointMent.fromDoc(e))
          .toList();
      return appointment;
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> deleteUsers(
      {required String userId, required String userDoc}) async {
    try {
      await firestore.collection(userId).doc(userDoc).delete();
    } on FirebaseException catch (e) {
      throw CustomError(
          code: e.code, message: e.message.toString(), plugin: '');
    } catch (e) {
      throw CustomError(message: e.toString());
    }
  }

  //! *********** Patient appointment length *****************
  Future<int> patientAppointmentLength({
    required String userId,
    required String name,
    required String surename,
  }) async {
    try {
      appointLength = await firestore
          .collection(userId)
          .where('name', isEqualTo: name)
          .where('surname', isEqualTo: surename)
          // .where('date', isNotEqualTo: Timestamp.fromMicrosecondsSinceEpoch(0))
          .get();
      patientLength =
          appointLength!.docs.map((e) => AppointMent.fromDoc(e)).toList();
      // print(patientLength.length - 1);
      return patientLength.length - 1;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> editPatient({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String userUid,
    required String docId,
  }) async {
    try {
      firestore.collection(userUid).doc(docId).update({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'description': description,
        // 'date': timestampday,
      }).then((_) {
        print("collection created");
      }).catchError((error) {
        print("An error occurred: $error");
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  // Future<AppointMent> seeUser(
  //     {required String userUid,
  //     required String name,
  //     required String surname}) async {
  //   try {
  //     appointMentsFromFirebase = await firestore
  //         .collection(userUid)
  //         .where('name', isEqualTo: name)
  //         .where('surname', isEqualTo: surname)
  //         .get();

  //     appointMent = appointMentsFromFirebase!.docs
  //         .map((e) => AppointMent.fromDoc(e))
  //         .first;
  //     print(appointMent);
  //     return appointMent!;
  //   } catch (e) {
  //     throw CustomError(
  //       code: 'Exception',
  //       message: e.toString(),
  //       plugin: 'flutter_error/server_error',
  //     );
  //   }
  // }
}
