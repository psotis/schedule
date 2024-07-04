import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';

List<AppointMent> appointment = [];
QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;
late final Stream<QuerySnapshot> usersStream;

class Test {
  final Stream<QuerySnapshot> usersStream =
      FirebaseFirestore.instance.collection('').snapshots();
}
