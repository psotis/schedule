import 'api_client.dart';

class StoreRepository {
  final ApiClient apiClient;
  StoreRepository({required this.apiClient});

  static const defaultWorkingDays = <int>[1, 2, 3, 4, 5];

  static List<int> workingDaysFromSettings(Object? settings) {
    final days = settings is Map ? settings['working_days'] : null;
    if (days is! List ||
        days.isEmpty ||
        days.any((day) => day is! int || day < 1 || day > 7)) {
      return List.of(defaultWorkingDays);
    }
    return days.cast<int>().toSet().toList()..sort();
  }

  Stream<void> get changes => apiClient.watch('store');

  Future<Map<String, dynamic>> getMessagingSettings() async =>
      Map<String, dynamic>.from(await apiClient.get('/store/messaging') as Map);

  Future<void> saveMessagingSettings(Map<String, dynamic> values) async {
    await apiClient.put('/store/messaging', body: values);
  }

  Future<void> removeMessagingSettings() async {
    await apiClient.delete('/store/messaging');
  }

  Future<Map<String, dynamic>> getMonthlyReportSettings() async {
    return Map<String, dynamic>.from(await apiClient.get('/reports/monthly-email') as Map);
  }

  Future<void> saveMonthlyReportSettings(bool enabled) async {
    await apiClient.put('/reports/monthly-email', body: {'enabled': enabled});
  }

  Future<Map<String, dynamic>> getCurrentStore() async {
    final data = await apiClient.get('/store');
    final store = data is Map ? data['store'] : null;
    return store is Map ? Map<String, dynamic>.from(store) : {};
  }

  Future<List<int>> getWorkingDays() async {
    final data = await apiClient.get('/store');
    final store = data is Map ? data['store'] : null;
    return workingDaysFromSettings(store is Map ? store['settings'] : null);
  }

  Future<void> saveWorkingDays(List<int> days) async {
    await apiClient.put('/store', body: {
      'settings': {'working_days': days},
    });
  }
}
