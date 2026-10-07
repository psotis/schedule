import 'package:scheldule/models/employee.dart';

import '../models/custom_errors.dart';
import 'api_client.dart';

class EmployeeRepository {
  final ApiClient apiClient;

  EmployeeRepository({required this.apiClient});

  Stream<List<Employee>> streamEmployee() async* {
    while (true) {
      yield await findEmployee();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<Employee>> findEmployee() async {
    try {
      final data = await apiClient.get('/employee') as List;
      return data
          .map((item) => Employee.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> addEmployee({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String address,
    required String amka,
    required String afm,
    required String specialiazation,
    required String contractType,
    String? color,
  }) async {
    try {
      await apiClient.post('/employee', body: {
        'first_name': name,
        'last_name': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'afm': afm,
        'specialization': specialiazation,
        'contract_type': contractType,
        'color': color ?? '',
      });
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }

  Future<void> removeEmployee({required String employeeId}) async {
    try {
      await apiClient.delete('/employee/$employeeId');
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
    required String amka,
    required String docId,
    required String afm,
    required String specialiazation,
    required String contractType,
    String? color,
  }) async {
    try {
      await apiClient.put('/employee/$docId', body: {
        'first_name': name,
        'last_name': surname,
        'phone': phone,
        'email': email,
        'address': address,
        'amka': amka,
        'afm': afm,
        'specialization': specialiazation,
        'contract_type': contractType,
        'color': color ?? '',
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
