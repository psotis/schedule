// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:scheldule/models/custom_errors.dart';

enum SignupStatus {
  initial,
  submitting,
  success,
  error,
}

class SignupState extends Equatable {
  final SignupStatus signupStatus;
  final CustomError error;
  SignupState({
    required this.signupStatus,
    required this.error,
  });

  factory SignupState.initial() {
    return SignupState(
      signupStatus: SignupStatus.initial,
      error: CustomError(),
    );
  }

  @override
  List<Object?> get props => [signupStatus, error];

  @override
  bool get stringify => true;

  SignupState copyWith({
    SignupStatus? signinStatus,
    CustomError? error,
  }) {
    return SignupState(
      signupStatus: signinStatus ?? signupStatus,
      error: error ?? this.error,
    );
  }
}
