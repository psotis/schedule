// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:scheldule/repositories/appointment_repository.dart';

import '../../models/appointment_model.dart';
import 'appointment_status.dart';

class AppointmentProvider extends ChangeNotifier {
  List<AppointMent> appointment = [];
  List<AppointMent> appointments = [];
  List<AppointMent> appointmentsByDate = [];
  AppointmentState _appointmentState = AppointmentState.initial();
  AppointmentState get appointmentState => _appointmentState;
  late String deleteDoc;

  final AppointmentRepository appointmentRepository;
  AppointmentProvider({
    required this.appointmentRepository,
  });

  Future<void> getAppointMents(DateTime selectedDay1, DateTime endOfDay) async {
    _appointmentState = _appointmentState.copyWith(
        appointmentStatus: AppointmentStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));
    try {
      appointment = await appointmentRepository.fetchAppointments();
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

  Future<void> getAppointMentsByDate({required DateTime date}) async {
    _appointmentState = _appointmentState.copyWith(
        appointmentStatus: AppointmentStatus.loading);
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));

    try {
      appointmentsByDate =
          await appointmentRepository.fetchAppointmentsByDate(date: date);
      if (appointmentsByDate.isEmpty) {
        _appointmentState = _appointmentState.copyWith(
            appointmentStatus: AppointmentStatus.empty);
        notifyListeners();
        return;
      }

      _appointmentState = _appointmentState.copyWith(
          appointMent: appointmentsByDate,
          appointmentStatus: AppointmentStatus.loaded);
      notifyListeners();
    } catch (e) {
      _appointmentState = _appointmentState.copyWith(
          appointmentStatus: AppointmentStatus.error);
      notifyListeners();
      throw Exception();
    }
  }

  Future<void> deleteAppointments(String appointmentId) async {
    await appointmentRepository.removeAppointment(appointmentId: appointmentId);

    _appointmentState =
        _appointmentState.copyWith(appointmentStatus: AppointmentStatus.delete);
    notifyListeners();
  }
}
