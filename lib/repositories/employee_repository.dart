import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/employee.dart';

import '../models/custom_errors.dart';

class EmployeeRepository {
  QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Employee>? mployee;

  Stream<List<Employee>> streamEmployee({required String userId}) {
    return FirebaseFirestore.instance
        .collection(userId)
        .where('specialization', isNull: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Employee.fromDoc(doc)).toList());
  }

  Future<void> addEmployee({
    required String userUid,
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String amka,
    required String afm,
    required String specialization,
    required String contractType,
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

  Future<void> removeEmployee(
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

  Future<void> editEmployee({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String description,
    required String amka,
    required String userUid,
    required String docId,
    required String afm,
    required String specialization,
    required String contractType,
  }) async {
    try {
      firestore.collection(userUid).doc(docId).update({
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
