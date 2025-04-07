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

  Stream<List<AppointMent>> streamUser({required String userId}) {
    return FirebaseFirestore.instance
        .collection(userId)
        .where('date', isEqualTo: Timestamp.fromMicrosecondsSinceEpoch(0))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointMent.fromDoc(doc)).toList());
  }

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
          .get();
      patientLength =
          appointLength!.docs.map((e) => AppointMent.fromDoc(e)).toList();
      print(patientLength);
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
    String? description,
    required String amka,
    required String userUid,
    required String docId,
    String? owes,
  }) async {
    try {
      final docRef = firestore.collection(userUid).doc(docId);
      final docSnapshot = await docRef.get();

      List<String> currentDescriptions = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        currentDescriptions = List<String>.from(data['description'] ?? []);
      }

      // Add new description to the list
      currentDescriptions.add(description ?? '');
      firestore.collection(userUid).doc(docId).update({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'description': currentDescriptions,
        'owes': owes ?? '',
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
}
