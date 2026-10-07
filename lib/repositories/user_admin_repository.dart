import 'api_client.dart';

class UserAdminRepository {
  final ApiClient apiClient;

  UserAdminRepository({required this.apiClient});

  Future<Map<String, dynamic>> getOverview() async {
    return Map<String, dynamic>.from(
      await apiClient.get('/user-admin/overview') as Map,
    );
  }
}
