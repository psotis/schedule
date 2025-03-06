import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';

class AddAppointmentRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<AppointMent>? appointment;

  Future<void> sendAppointments({
    required String userUid,
    required String surname,
    required Timestamp date,
    required String name,
    String? employee,
    String? position,
  }) async {
    try {
      FirebaseFirestore.instance.collection(userUid).add({
        'name': name,
        'surname': surname,
        'phone': '',
        'email': '',
        'address': '',
        'description': '',
        'amka': '',
        'date': date,
        'position': position,
        'employee': employee,
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
