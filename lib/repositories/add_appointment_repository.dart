import 'package:flutter/material.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/booking_models.dart';
import 'package:scheldule/models/employee.dart';

import '../models/app_timestamp.dart';
import '../models/custom_errors.dart';
import 'api_client.dart';

class AddAppointmentRepository {
  final ApiClient apiClient;

  AddAppointmentRepository({required this.apiClient});

  Future<List<AppointMent>> getClients({String query = ''}) async {
    final data = await apiClient.get(
      '/client',
      query: query.trim().isEmpty ? null : {'q': query.trim()},
    ) as List;
    return data
        .map((item) => AppointMent.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AppointMent?> findDuplicateClient(String phone) async {
    final data = await apiClient.get(
      '/client-duplicate',
      query: {'phone': phone},
    );
    if (data == null) return null;
    return AppointMent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AppointMent> createClient({
    required String name,
    required String surname,
    required String phone,
    String email = '',
    String source = '',
    bool allowDuplicate = false,
  }) async {
    final data = await apiClient.post('/client', body: {
      'first_name': name,
      'last_name': surname,
      'phone': phone,
      'email': email,
      'source': source,
      'address': '',
      'afm': '',
      'amka': '',
      'client_description': '',
      'owes': 0,
      'allow_duplicate': allowDuplicate,
    }) as Map;
    return AppointMent.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ServiceOffering>> getServices() async {
    final data = await apiClient.get('/services') as List;
    return data
        .map((item) =>
            ServiceOffering.fromJson(Map<String, dynamic>.from(item as Map)))
        .where((service) => service.isActive)
        .toList();
  }

  Future<List<Employee>> getEmployees({String? serviceId}) async {
    final data = await apiClient.get(
      '/employee',
      query: serviceId == null ? null : {'service_id': serviceId},
    ) as List;
    return data
        .map(
            (item) => Employee.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<StoreStation>> getStations() async {
    final data = await apiClient.get('/position') as List;
    return data
        .map((item) =>
            StoreStation.fromJson(Map<String, dynamic>.from(item as Map)))
        .where((station) => station.isActive)
        .toList();
  }

  Future<AppointMent> createBooking({
    required String clientId,
    required DateTime start,
    required List<Map<String, dynamic>> services,
    String? stationId,
    String notes = '',
  }) async {
    final totalMinutes = services.fold<int>(
      0,
      (sum, item) =>
          sum +
          (num.tryParse(item['duration_minutes'].toString())?.round() ?? 0),
    );
    final end = start.add(Duration(minutes: totalMinutes));
    final data = await apiClient.post('/appointment', body: {
      'client_id': clientId,
      'date': _dateOnly(start),
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
      if (stationId != null && stationId.isNotEmpty) 'positions_id': stationId,
      'services': services,
      'status': 'scheduled',
      'notes': notes,
    }) as Map;
    return AppointMent.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ServiceOffering> saveService({
    String? id,
    required String name,
    required String category,
    required String subcategory,
    required double price,
    required int durationMinutes,
  }) async {
    final body = {
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_active': true,
    };
    final data = id == null
        ? await apiClient.post('/services', body: body)
        : await apiClient.put('/services/$id', body: body);
    return ServiceOffering.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<StoreStation> saveStation({
    String? id,
    required String name,
    required int capacity,
  }) async {
    final body = {
      'description': name,
      'max_persons': capacity,
      'is_active': true,
    };
    final data = id == null
        ? await apiClient.post('/position', body: body)
        : await apiClient.put('/position/$id', body: body);
    return StoreStation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> setEmployeeServices({
    required String employeeId,
    required List<String> serviceIds,
  }) async {
    await apiClient.put('/employee/$employeeId/services', body: {
      'service_ids': serviceIds,
    });
  }

  Future<void> setEmployeeAvailability({
    required String employeeId,
    required List<Map<String, dynamic>> availability,
  }) async {
    await apiClient.put('/employee/$employeeId/availability', body: {
      'availability': availability,
    });
  }

  Future<List<Map<String, dynamic>>> getEmployeeTimeOff() async {
    final data = await apiClient.get('/employee-time-off') as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> addEmployeeTimeOff({
    required String employeeId,
    required DateTime startsAt,
    required DateTime endsAt,
    String reason = '',
  }) async {
    await apiClient.post('/employee-time-off', body: {
      'employee_id': employeeId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'reason': reason,
    });
  }

  Future<void> deleteEmployeeTimeOff(String id) async {
    await apiClient.delete('/employee-time-off/$id');
  }

  Future<List<Map<String, dynamic>>> getStoreMembers() async {
    final data = await apiClient.get('/store/members') as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> addStoreMember({
    required String email,
    required String role,
  }) async {
    await apiClient.post('/store/members', body: {
      'email': email,
      'role': role,
    });
  }

  Future<void> updateStoreMember({
    required String membershipId,
    required String role,
    required bool isActive,
  }) async {
    await apiClient.put('/store/members/$membershipId', body: {
      'role': role,
      'is_active': isActive,
    });
  }

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
