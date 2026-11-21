import 'api_client.dart';

class BillingRepository {
  final ApiClient apiClient;
  BillingRepository({required this.apiClient});

  Future<Map<String, dynamic>> status() async => Map<String, dynamic>.from(
        await apiClient.get('/billing/subscription') as Map,
      );
  Future<void> startTrial() => apiClient.post('/billing/trial');
  Future<String> checkout(String plan) async {
    final data = await apiClient.post(
      '/billing/checkout',
      body: {'plan_code': plan},
    ) as Map;
    return data['checkout_url'] as String;
  }

  Future<void> confirm(String transactionId) => apiClient.post(
        '/billing/confirm',
        body: {'transaction_id': transactionId},
      );
}
