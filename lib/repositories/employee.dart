import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';

class AddEmployeeRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<AppointMent>? appointment;

  Future<void> addEmployee({
    required String userUid,
    required String name,
    required String surname,
    required String phone,
    String? email,
    String? address,
    String? description,
    String? amka,
    String? afm,
    String? specialization,
    String? contractType,
  }) async {
    try {
      FirebaseFirestore.instance
          .collection(userUid)
          .doc('Employee $name $surname')
          .set({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'description': description,
        'amka': amka,
        'afm': afm,
        'specialiazation': specialization,
        'contract_type': contractType,
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
