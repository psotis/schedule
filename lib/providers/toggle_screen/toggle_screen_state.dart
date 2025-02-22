// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import '../../models/appointment_model.dart';

enum ToggleStatus { no, yes }

class ToggleState extends Equatable {
  final ToggleStatus toggleStatus;
  final AppointMent customer;
  ToggleState({required this.toggleStatus, required this.customer});
  factory ToggleState.initial() {
    return ToggleState(
        customer: AppointMent.initial(), toggleStatus: ToggleStatus.no);
  }

  @override
  List<Object?> get props => [customer, toggleStatus];

  ToggleState copyWith({ToggleStatus? toggleStatus, AppointMent? customer}) {
    return ToggleState(
      toggleStatus: toggleStatus ?? this.toggleStatus,
      customer: customer ?? this.customer,
    );
  }

  @override
  bool get stringify => true;
}
