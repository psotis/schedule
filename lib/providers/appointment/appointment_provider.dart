// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:scheldule/repositories/appointment_repository.dart';

import '../../models/appointment_model.dart';
import 'appointment_status.dart';

class AppointmentProvider extends ChangeNotifier {
  List<AppointMent> appointment = [];
  List<AppointMent> appointments = [];
  AppointmentState _appointmentState = AppointmentState.initial();
  AppointmentState get appointmentState => _appointmentState;
  late DocumentReference documentReference;
  late String deleteDoc;
  User? user;

  // QuerySnapshot<Map<String, dynamic>>? appointMentsFromFirebase;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final AppointmentRepository appointmentRepository;
  AppointmentProvider({
    required this.appointmentRepository,
  });

  // Stream<List<AppointMent>> getApp(String userId) {
  //   // return appointmentRepository.streamAppointment(userId: userId);
  //   _appointmentState = _appointmentState.copyWith(
  //       appointmentStatus: AppointmentStatus.loading);
  //   try {
  //     // Use the streamAppointment method from your repository
  //     return appointmentRepository
  //         .streamAppointment(userId: userId)
  //         .map((appointments) {
  //       // Update the state based on the data received
  //       if (appointments.isEmpty) {
  //         _appointmentState = _appointmentState.copyWith(
  //             appointMent: appointments,
  //             appointmentStatus: AppointmentStatus.empty);
  //       } else {
  //         _appointmentState = _appointmentState.copyWith(
  //             appointMent: appointments,
  //             appointmentStatus: AppointmentStatus.loaded);
  //       }
  //       notifyListeners();
  //       return appointments;
  //     });
  //   } catch (e) {
  //     throw CustomError(message: e.toString());
  //   }
  // }

  Future<void> getAppointMents(
      String userid, DateTime selectedDay1, DateTime endOfDay) async {
    _appointmentState = _appointmentState.copyWith(
        appointmentStatus: AppointmentStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));
    print('$selectedDay1 and $endOfDay');

    //! This is for patient count appointments
    // var app = await firestore
    //     .collection(userid)
    //     .where('name', isEqualTo: 'Τασος')
    //     .where('surname', isEqualTo: 'Ψαρρης')
    //     .get();
    // print(app.docs.length);

    try {
      appointment =
          await appointmentRepository.fetchAppointments(userid: userid);
      if (appointment.isEmpty) {
        _appointmentState = _appointmentState.copyWith(
            appointMent: [], appointmentStatus: AppointmentStatus.empty);
        notifyListeners();
      }

      _appointmentState = _appointmentState.copyWith(
          appointMent: appointment,
          appointmentStatus: AppointmentStatus.loaded);
      notifyListeners();
      // _appointmentState = _appointmentState.copyWith(
      //     appointMent: appointment,
      //     appointmentStatus: AppointmentStatus.initial);
      // notifyListeners();
    } catch (e) {
      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AppointmentStatus.error);
      notifyListeners();
      throw Exception();
    }
  }

  Future<void> deleteAppointments(String userId, String userDoc) async {
    await appointmentRepository.removeAppointment(
        userId: userId, userDoc: userDoc);

    _appointmentState =
        _appointmentState.copyWith(appointmentStatus: AppointmentStatus.delete);
    notifyListeners();
  }
}
