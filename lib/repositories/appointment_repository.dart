import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';

class AppointmentRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<AppointMent>? appointment;

  Stream<List<AppointMent>> streamAppointment({required String userId}) {
    return FirebaseFirestore.instance
        .collection(userId)
        .where('date', isGreaterThanOrEqualTo: DateTime(2020))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointMent.fromDoc(doc)).toList());
  }

  Future<List<AppointMent>> fetchAppointments({required String userid}) async {
    try {
      appointMentsFromFirebase = await firestore
          .collection(userid)
          .where('date', isGreaterThanOrEqualTo: DateTime(2020))
          // .where('date', isLessThan: endOfDay)
          .get();
      appointment = appointMentsFromFirebase!.docs
          .map((e) => AppointMent.fromDoc(e))
          .toList();
      return appointment!;
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> removeAppointment(
      {required String userId, required String userDoc}) async {
    try {
      firestore.collection(userId).doc(userDoc).delete();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }
}
