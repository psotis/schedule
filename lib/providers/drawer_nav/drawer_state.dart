// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

enum DrawerStatus { calendar, employee, customer, appointments, settings }

class DrawerState with EquatableMixin {
  final DrawerStatus drawerStatus;
  final String title;

  DrawerState({required this.drawerStatus, required this.title});

  factory DrawerState.initial() {
    return DrawerState(drawerStatus: DrawerStatus.calendar, title: 'Calendar');
  }

  @override
  List<Object> get props => [drawerStatus, title];

  DrawerState copyWith({
    DrawerStatus? drawerStatus,
    String? title,
  }) {
    return DrawerState(
      drawerStatus: drawerStatus ?? this.drawerStatus,
      title: title ?? this.title,
    );
  }
}
