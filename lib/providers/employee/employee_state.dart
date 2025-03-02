// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:scheldule/models/employee.dart';

enum EmployeeStatus {
  initial,
  loading,
  loaded,
  send,
  update,
  delete,
  error,
}

class EmployeeState extends Equatable {
  final List<Employee> employee;
  final EmployeeStatus employeeStatus;
  EmployeeState({
    required this.employee,
    required this.employeeStatus,
  });

  factory EmployeeState.initial() {
    return EmployeeState(employee: [], employeeStatus: EmployeeStatus.initial);
  }

  @override
  List<Object> get props => [employee, employeeStatus];

  EmployeeState copyWith({
    List<Employee>? employee,
    EmployeeStatus? employeeStatus,
  }) {
    return EmployeeState(
      employee: employee ?? this.employee,
      employeeStatus: employeeStatus ?? this.employeeStatus,
    );
  }

  @override
  bool get stringify => true;
}
