import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';

class AppointmentRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebaseByDate;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<AppointMent>? appointment;

  Stream<List<AppointMent>>? streamAppointment({required String userId}) {
    return firestore
        .collection(userId)
        .where('date', isGreaterThanOrEqualTo: DateTime(2020))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointMent.fromDoc(doc)).toList());
  }

  Stream<List<AppointMent>>? streamTodayAppointment({required String userId}) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return firestore
        .collection(userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
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

  Future<List<AppointMent>> fetchAppointmentsByDate(
      {required String userid, required DateTime date}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    try {
      appointMentsFromFirebaseByDate = await firestore
          .collection(userid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      appointment = appointMentsFromFirebaseByDate!.docs
          .map((e) => AppointMent.fromDoc(e))
          .toList();
      print(appointment);
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
