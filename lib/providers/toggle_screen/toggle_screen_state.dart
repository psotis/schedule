// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:scheldule/models/employee.dart';

import '../../models/appointment_model.dart';

enum ToggleStatus { no, yes }

class ToggleState extends Equatable {
  final ToggleStatus toggleStatus;
  final AppointMent customer;
  final Employee employee;
  ToggleState(
      {required this.toggleStatus,
      required this.customer,
      required this.employee});
  factory ToggleState.initial() {
    return ToggleState(
        customer: AppointMent.initial(),
        employee: Employee.initial(),
        toggleStatus: ToggleStatus.no);
  }

  @override
  List<Object?> get props => [customer, employee, toggleStatus];

  ToggleState copyWith(
      {ToggleStatus? toggleStatus, AppointMent? customer, Employee? employee}) {
    return ToggleState(
      toggleStatus: toggleStatus ?? this.toggleStatus,
      employee: employee ?? this.employee,
      customer: customer ?? this.customer,
    );
  }

  @override
  bool get stringify => true;
}
