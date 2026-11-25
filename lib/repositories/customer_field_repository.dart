import '../models/customer_field.dart';
import 'api_client.dart';

class CustomerFieldRepository {
  CustomerFieldRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<List<CustomerField>> getDefinitions() async {
    final data = await apiClient.get('/store/client-fields') as List;
    return data
        .map(
          (item) =>
              CustomerField.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getValues(String clientId) async {
    final data = await apiClient.get('/client/$clientId/custom-fields') as List;
    return {
      for (final item in data)
        item['field_definition_id'].toString(): item['value'],
    };
  }

  Future<void> saveValues(String clientId, Map<String, dynamic> values) async {
    await apiClient.put('/client/$clientId', body: {'custom_fields': values});
  }

  Future<void> setVisible(String fieldId, bool visible) async {
    await apiClient.put(
      '/store/client-fields/$fieldId',
      body: {'is_active': visible},
    );
  }

  Future<List<Map<String, dynamic>>> getReferences(String path) async {
    final data = await apiClient.get(path) as List;
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['is_active'] != false)
        .toList();
  }
}
