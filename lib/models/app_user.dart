import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role;
  final String activeStoreId;
  final String storeRole;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.activeStoreId,
    required this.storeRole,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: (json['uuid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      photoUrl: (json['profile_image'] ?? '').toString(),
      role: (json['role'] ?? 'admin').toString(),
      activeStoreId: (json['active_store_id'] ?? '').toString(),
      storeRole: (json['active_store_role'] ?? 'owner').toString(),
    );
  }

  AppUser copyWith({String? activeStoreId}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      storeRole: storeRole,
    );
  }

  @override
  List<Object> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        role,
        activeStoreId,
        storeRole,
      ];
}
