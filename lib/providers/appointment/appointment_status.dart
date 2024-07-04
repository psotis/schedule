// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:scheldule/models/appointment_model.dart';

enum AppointmentStatus {
  initial,
  loading,
  loaded,
  error,
  empty,
  delete,
  addAppointment
}

class AppointmentState extends Equatable {
  final List<AppointMent> appointMent;
  final AppointmentStatus appointmentStatus;
  AppointmentState({
    required this.appointMent,
    required this.appointmentStatus,
  });

  factory AppointmentState.initial() {
    return AppointmentState(
        appointMent: [], appointmentStatus: AppointmentStatus.initial);
  }

  @override
  List<Object> get props => [appointMent, appointmentStatus];

  AppointmentState copyWith({
    List<AppointMent>? appointMent,
    AppointmentStatus? appointmentStatus,
  }) {
    return AppointmentState(
      appointMent: appointMent ?? this.appointMent,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
    );
  }

  @override
  bool get stringify => true;
}
