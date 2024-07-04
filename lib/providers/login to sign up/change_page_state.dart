import 'package:equatable/equatable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ChangePageStatus { login, signup }

class ChangePageState extends Equatable {
  final ChangePageStatus changePageStatus;
  ChangePageState({
    required this.changePageStatus,
  });

  factory ChangePageState.initial() {
    return ChangePageState(changePageStatus: ChangePageStatus.login);
  }

  @override
  List<Object> get props => [changePageStatus];

  ChangePageState copyWith({
    ChangePageStatus? changePageStatus,
  }) {
    return ChangePageState(
      changePageStatus: changePageStatus ?? this.changePageStatus,
    );
  }

  @override
  bool get stringify => true;
}
