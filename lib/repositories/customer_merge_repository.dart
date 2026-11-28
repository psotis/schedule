import 'api_client.dart';

class CustomerMergeRepository {
  CustomerMergeRepository({required this.apiClient});
  final ApiClient apiClient;
  Future<Map<String, dynamic>> getSettings() async => Map<String, dynamic>.from(
    await apiClient.get('/store/customer-merge-settings') as Map,
  );
  Future<void> setEnabled(bool enabled) async {
    await apiClient.put(
      '/store/customer-merge-settings',
      body: {'enabled': enabled},
    );
  }

  Future<List<Map<String, dynamic>>> history() async =>
      ((await apiClient.get('/client-merges')) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  Future<List<Map<String, dynamic>>> getCustomers() async =>
      ((await apiClient.get('/client')) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  Future<Map<String, dynamic>> preview(String source, String target) async =>
      Map<String, dynamic>.from(
        await apiClient.get(
          '/client/$source/merge-preview',
          query: {'target_id': target},
        ) as Map,
      );
  Future<Map<String, dynamic>> merge(
    String source,
    String target,
    String token,
  ) async => Map<String, dynamic>.from(
    await apiClient.post(
      '/client/$source/merge',
      body: {
        'target_id': target,
        'preview_token': token,
        'confirm_same_customer': true,
      },
    ) as Map,
  );
}
