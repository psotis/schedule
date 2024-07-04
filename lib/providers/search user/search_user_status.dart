import 'package:equatable/equatable.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/custom_errors.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
enum SearchUserStatus {
  initial,
  loading,
  loaded,
  sent,
  error,
  bringEditedUser,
  empty,
  loadedList,
  delete,
}

class SearchUserState extends Equatable {
  final SearchUserStatus searchUserStatus;
  final List<AppointMent> appointMent;
  final CustomError error;
  SearchUserState({
    required this.searchUserStatus,
    required this.appointMent,
    required this.error,
  });
  factory SearchUserState.initial() {
    return SearchUserState(
      searchUserStatus: SearchUserStatus.initial,
      error: CustomError(),
      appointMent: [],
    );
  }

  @override
  List<Object> get props => [searchUserStatus, appointMent];

  SearchUserState copyWith({
    SearchUserStatus? searchUserStatus,
    List<AppointMent>? appointMent,
    CustomError? error,
  }) {
    return SearchUserState(
      searchUserStatus: searchUserStatus ?? this.searchUserStatus,
      appointMent: appointMent ?? this.appointMent,
      error: error ?? this.error,
    );
  }

  @override
  bool get stringify => true;
}
