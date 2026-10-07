import 'package:flutter/material.dart';
import 'package:scheldule/models/appointment_model.dart';

import '../models/app_timestamp.dart';
import '../models/custom_errors.dart';
import 'api_client.dart';

class AddAppointmentRepository {
  final ApiClient apiClient;

  AddAppointmentRepository({required this.apiClient});

  Future<Map<String, dynamic>?> _findClient(
    String name,
    String surname,
  ) async {
    final clients = await apiClient.get('/client') as List;
    final normalizedName = name.trim().toLowerCase();
    final normalizedSurname = surname.trim().toLowerCase();
    for (final item in clients) {
      final client = Map<String, dynamic>.from(item);
      if ((client['first_name'] ?? '').toString().trim().toLowerCase() ==
              normalizedName &&
          (client['last_name'] ?? '').toString().trim().toLowerCase() ==
              normalizedSurname) {
        return client;
      }
    }
    return null;
  }

  Future<bool> checkForUser({
    required String name,
    required String surname,
  }) async {
    try {
      return await _findClient(name, surname) != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendAppointments(
    BuildContext context, {
    required String surname,
    required Timestamp date,
    required String name,
    String? employee,
    String? position,
    String? owes,
    int? paid,
  }) async {
    try {
      var client = await _findClient(name, surname);
      client ??=
          Map<String, dynamic>.from(await apiClient.post('/client', body: {
        'first_name': name,
        'last_name': surname,
        'phone': '',
        'email': '',
        'address': '',
        'afm': '',
        'amka': '',
        'client_description': '',
        'owes': 0,
      }) as Map);

      final employeeId = await _findEmployeeId(employee);
      final positionId = await _findPositionId(position);
      final start = date.toDate();
      await apiClient.post('/appointment', body: {
        'client_id': client['uuid'],
        'date': _dateOnly(start),
        'start_time': start.toUtc().toIso8601String(),
        'end_time':
            start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
        if (employeeId != null) 'employee_id': employeeId,
        if (positionId != null) 'positions_id': positionId,
        'paid': paid ?? 0,
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> editAppointment(
    BuildContext context, {
    required String appointmentId,
    required String name,
    required String surname,
    required Timestamp date,
    String? position,
    String? employee,
    String? owes,
    int? paid,
  }) async {
    try {
      final client = await _findClient(name, surname);
      final employeeId = await _findEmployeeId(employee);
      final positionId = await _findPositionId(position);
      final start = date.toDate();
      await apiClient.put('/appointment/$appointmentId', body: {
        if (client != null) 'client_id': client['uuid'],
        'date': _dateOnly(start),
        'start_time': start.toUtc().toIso8601String(),
        'end_time':
            start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
        'employee_id': employeeId,
        'positions_id': positionId,
        'paid': paid ?? 0,
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: 'Failed to update appointment: $e',
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<String?> _findEmployeeId(String? fullName) async {
    if (fullName == null || fullName.trim().isEmpty) return null;
    final employees = await apiClient.get('/employee') as List;
    final wanted = fullName.trim().toLowerCase();
    for (final item in employees) {
      final employee = Map<String, dynamic>.from(item);
      final name =
          '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
              .trim()
              .toLowerCase();
      if (name == wanted) return employee['uuid']?.toString();
    }
    return null;
  }

  Future<String?> _findPositionId(String? description) async {
    if (description == null || description.trim().isEmpty) return null;
    final positions = await apiClient.get('/position') as List;
    final wanted = description.trim().toLowerCase();
    for (final item in positions) {
      final position = Map<String, dynamic>.from(item);
      if ((position['description'] ?? '').toString().trim().toLowerCase() ==
          wanted) {
        return position['uuid']?.toString();
      }
    }
    return null;
  }

  String _dateOnly(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
