import 'package:flutter_test/flutter_test.dart';
import 'package:scheldule/models/app_timestamp.dart';
import 'package:scheldule/models/app_user.dart';

void main() {
  test('service user and timestamp models preserve API values', () {
    final user = AppUser.fromJson({
      'uuid': 'user-id',
      'email': 'owner@example.com',
      'display_name': 'Owner',
      'profile_image': '',
      'role': 'admin',
      'active_store_id': 'store-id',
    });
    final timestamp = Timestamp.fromJson('2026-10-07T10:30:00.000Z');

    expect(user.uid, 'user-id');
    expect(user.activeStoreId, 'store-id');
    expect(timestamp.toDate().toUtc().hour, 10);
  });
}
