import 'api_client.dart';

class UserAdminRepository {
  final ApiClient apiClient;
  UserAdminRepository({required this.apiClient});

  Future<Map<String, dynamic>> getOverview(
          {int? year, int month = 0, int page = 1, String search = ''}) async =>
      Map<String, dynamic>.from(
          await apiClient.get('/user-admin/overview', query: {
        'year': '${year ?? DateTime.now().year}',
        'month': '$month',
        'page': '$page',
        'search': search,
      }) as Map);

  Future<void> manageUser(String id, String action, {String? password}) async {
    await apiClient.put('/user-admin/users/$id',
        body: {'action': action, if (password != null) 'password': password});
  }

  Future<void> manageStore(String id, String action) async {
    await apiClient.put('/user-admin/stores/$id', body: {'action': action});
  }

  Future<void> blockEmail(String email,
      {bool block = true, String reason = ''}) async {
    await apiClient.put('/user-admin/email-blocks', body: {
      'email': email,
      'action': block ? 'block' : 'unblock',
      'reason': reason
    });
  }

  Future<Map<String, dynamic>> records(
          String id, String section, int page) async =>
      Map<String, dynamic>.from(await apiClient.get(
          '/user-admin/stores/$id/records',
          query: {'section': section, 'page': '$page'}) as Map);
}
