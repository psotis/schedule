import 'api_client.dart';

class UiPreferencesRepository {
  final ApiClient apiClient;
  UiPreferencesRepository({required this.apiClient});

  Future<Map<String, String>> load() async {
    final data = await apiClient.get('/store/preferences') as Map;
    return data.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> save(String key, String value) async {
    await apiClient.put('/store/preferences', body: {key: value});
  }
}
