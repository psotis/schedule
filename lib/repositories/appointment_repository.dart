import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';
import 'api_client.dart';

class AppointmentRepository {
  final ApiClient apiClient;

  AppointmentRepository({required this.apiClient});

  Stream<List<AppointMent>> streamAppointment() async* {
    while (true) {
      yield await fetchAppointments();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Stream<List<AppointMent>> streamTodayAppointment() async* {
    while (true) {
      yield await fetchAppointmentsByDate(date: DateTime.now());
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<AppointMent>> fetchAppointments() async {
    try {
      final data = await apiClient.get('/appointments') as List;
      return data
          .map((item) => AppointMent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<List<AppointMent>> fetchAppointmentPaid(
      {required String name, required String surname}) async {
    try {
      final appointments = await fetchAppointments();
      return appointments
          .where((item) => item.name == name && item.surname == surname)
          .toList();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<List<AppointMent>> fetchAppointmentsByDate(
      {required DateTime date}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    try {
      final data = await apiClient.get('/appointments', query: {
        'from': _dateOnly(startOfDay),
        'to': _dateOnly(endOfDay),
      }) as List;
      return data
          .map((item) => AppointMent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> removeAppointment({required String appointmentId}) async {
    try {
      await apiClient.delete('/appointment/$appointmentId');
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
