import 'package:equatable/equatable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
enum AddUserStatus { initial, loading, sent, error, bringUser }

class AddUserState extends Equatable {
  final AddUserStatus addUserStatus;
  AddUserState({
    required this.addUserStatus,
  });

  factory AddUserState.initial() {
    return AddUserState(addUserStatus: AddUserStatus.initial);
  }

  @override
  List<Object> get props => [addUserStatus];

  AddUserState copyWith({
    AddUserStatus? addUserStatus,
  }) {
    return AddUserState(
      addUserStatus: addUserStatus ?? this.addUserStatus,
    );
  }

  @override
  bool get stringify => true;
}
