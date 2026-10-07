import 'package:equatable/equatable.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final int point;
  final String rank;
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.point,
    required this.rank,
  });

  factory User.fromJson(Map<String, dynamic> userData) {
    return User(
      id: (userData['uuid'] ?? '').toString(),
      name: (userData['display_name'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
      profileImage: (userData['profile_image'] ?? '').toString(),
      point: 0,
      rank: (userData['role'] ?? '').toString(),
    );
  }
  //! Gia otan prospathisei na diavasei ta stoixeia prin to login, na exei arxikes times gia na mhn vgainoun null
  factory User.initialUser() {
    return User(
      id: '',
      name: '',
      email: '',
      profileImage: '',
      point: -1,
      rank: '',
    );
  }

  @override
  List<Object> get props {
    return [
      id,
      name,
      email,
      profileImage,
      point,
      rank,
    ];
  }

  @override
  bool get stringify => true;
}
