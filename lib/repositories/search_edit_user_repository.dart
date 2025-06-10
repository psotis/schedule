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
        // .orderBy('name')
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

    // New optional fields
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
    try {
      final docRef = firestore.collection(userUid).doc(docId);
      final docSnapshot = await docRef.get();

      List<String> currentDescriptions = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        currentDescriptions = List<String>.from(data['description'] ?? []);
      }

      // Add new description to the list if it is not null or empty
      if (description != null && description.isNotEmpty) {
        currentDescriptions.add(description);
      }

      await docRef.update({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'description': currentDescriptions,
        'owes': owes ?? '',

        // Add the new fields here, they will update or add in Firestore
        'heart': heart,
        'breathe': breathe,
        'sugar': sugar,
        'ypertash': ypertash,
        'neuro': neuro,
        'orthopedic': orthopedic,
        'selfCare': selfCare,
        'helpCare': helpCare,
        'disabled': disabled,
        'good': good,
        'medium': medium,
        'bad': bad,
        'yes': yes,
        'no': no,
        'birthday': birthday,
        'allo': allo,
        'startingDate': startingDate,
        'mainIssue': mainIssue,
        'doctor': doctor,
        'surgeryPast': surgeryPast,
        'surgeryNow': surgeryNow,
        'pharmacy': pharmacy,
        'allergies': allergies,
        'spot': spot,
        'missFunctions': missFunctions,
      });

      print("Document updated successfully");
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }
}
