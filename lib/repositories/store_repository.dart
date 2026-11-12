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
