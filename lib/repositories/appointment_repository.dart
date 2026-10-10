import 'package:scheldule/models/appointment_model.dart';

import '../models/custom_errors.dart';
import 'api_client.dart';

class AppointmentRepository {
  final ApiClient apiClient;

  AppointmentRepository({required this.apiClient});

  Stream<void> get changes => apiClient.watch('appointments');

  Stream<List<AppointMent>> streamAppointment() async* {
    yield await fetchAppointments();
    await for (final _ in changes) {
      yield await fetchAppointments();
    }
  }

  Stream<List<AppointMent>> streamTodayAppointment() async* {
    yield await fetchAppointmentsByDate(date: DateTime.now());
    await for (final _ in changes) {
      yield await fetchAppointmentsByDate(date: DateTime.now());
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

  Future<AppointMent> updateStatus({
    required AppointMent appointment,
    required String status,
  }) async {
    final data = await apiClient.put('/appointment/${appointment.id}', body: {
      'status': status,
    }) as Map;
    return AppointMent.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> addPayment({
    required String appointmentId,
    required double amount,
    required String method,
    bool complete = false,
  }) async {
    await apiClient.post('/appointment/$appointmentId/payments', body: {
      'amount': amount,
      'method': method,
      'complete': complete,
    });
  }

  Future<Map<String, dynamic>> getReport({
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    return Map<String, dynamic>.from(
      await apiClient.get(
        '/reports/overview',
        query: query.isEmpty ? null : query,
      ) as Map,
    );
  }

  Future<Map<String, dynamic>> getClientReport(String clientId) async {
    return Map<String, dynamic>.from(
      await apiClient.get('/reports/client/$clientId') as Map,
    );
  }

  String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
