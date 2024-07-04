// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:scheldule/models/appointment_model.dart';

enum AddAppointmentStatus {
  initial,
  loading,
  loaded,
  error,
  empty,
  delete,
  addAppointment
}

class AddAppointmentState extends Equatable {
  final List<AppointMent> appointMent;
  final AddAppointmentStatus appointmentStatus;
  AddAppointmentState({
    required this.appointMent,
    required this.appointmentStatus,
  });

  factory AddAppointmentState.initial() {
    return AddAppointmentState(
        appointMent: [], appointmentStatus: AddAppointmentStatus.initial);
  }

  @override
  List<Object> get props => [appointMent, appointmentStatus];

  AddAppointmentState copyWith({
    List<AppointMent>? appointMent,
    AddAppointmentStatus? appointmentStatus,
  }) {
    return AddAppointmentState(
      appointMent: appointMent ?? this.appointMent,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
    );
  }

  @override
  bool get stringify => true;
}
