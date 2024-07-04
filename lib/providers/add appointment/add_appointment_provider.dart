import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../repositories/add_appointment_repository.dart';
import 'add_appointment_status.dart';

class AddAppointmentProvider extends ChangeNotifier {
  List<AppointMent> appointment = [];
  AddAppointmentState _appointmentState = AddAppointmentState.initial();
  AddAppointmentState get appointmentState => _appointmentState;

  final AddAppointmentRepository addAppointmentRepository;
  AddAppointmentProvider({
    required this.addAppointmentRepository,
  });

  Future<void> addAppointment({
    required String name,
    required String surname,
    required Timestamp date,
    required String userUid,
  }) async {
    _appointmentState = _appointmentState.copyWith(
        appointmentStatus: AddAppointmentStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await addAppointmentRepository.sendAppointments(
          userUid: userUid, surname: surname, date: date, name: name);

      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AddAppointmentStatus.loaded);
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 2));
      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AddAppointmentStatus.addAppointment);
      notifyListeners();
      await Future.delayed(Duration(seconds: 2));
      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AddAppointmentStatus.initial);
      notifyListeners();
    } catch (e) {
      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AddAppointmentStatus.error);
      notifyListeners();
      throw Exception();
    }
  }
}
