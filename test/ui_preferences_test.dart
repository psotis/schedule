import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';

class _SessionApi extends ApiClient {
  final changes = StreamController<int>.broadcast();
  String scope = 'first-user:first-store';
  int revision = 0;
  @override
  bool get hasSession => true;
  @override
  String get activeStoreId => scope;
  @override
  int get sessionRevision => revision;
  @override
  Stream<int> get sessionChanges => changes.stream;
  void switchSession(String next) {
    scope = next;
    changes.add(++revision);
  }
}

class _MemoryRepository extends UiPreferencesRepository {
  final Map<String, Map<String, String>> stored = {};
  final List<String> writes = [];
  Completer<void>? nextLoad;
  Completer<void>? nextSave;
  bool failSaves = false;
  _MemoryRepository(_SessionApi api) : super(apiClient: api);
  @override
  Future<Map<String, String>> load() async {
    final snapshot =
        Map<String, String>.from(stored[apiClient.activeStoreId] ?? {});
    final barrier = nextLoad;
    nextLoad = null;
    await barrier?.future;
    return snapshot;
  }

  @override
  Future<void> save(String key, String value) async {
    final scope = apiClient.activeStoreId!;
    final barrier = nextSave;
    nextSave = null;
    writes.add('$scope:$key:$value');
    await barrier?.future;
    if (failSaves) throw StateError('Save failed');
    (stored[scope] ??= {})[key] = value;
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
      'preferences restore, serialize rapid choices, and roll back failed saves',
      () async {
    final api = _SessionApi();
    final repository = _MemoryRepository(api);
    repository.stored[api.scope] = {
      'calendar_layout': 'agenda',
      'customers_view': 'list'
    };
    final provider = UiPreferencesProvider(repository: repository);
    await _flush();
    expect(provider.value('calendar_layout', fallback: 'day'), 'agenda');
    await Future.wait([
      provider.setValue('customers_view', 'grid'),
      provider.setValue('customers_view', 'list'),
      provider.setValue('employees_view', 'grid'),
    ]);
    expect(repository.stored[api.scope], {
      'calendar_layout': 'agenda',
      'customers_view': 'list',
      'employees_view': 'grid'
    });
    repository.failSaves = true;
    await Future.wait([
      provider.setValue('customers_view', 'grid'),
      provider.setValue('customers_view', 'grid'),
    ]);
    expect(provider.value('customers_view', fallback: 'grid'), 'list');
    expect(provider.error, isNotNull);
    provider.dispose();
    final restored = UiPreferencesProvider(repository: repository);
    await _flush();
    expect(restored.value('employees_view', fallback: 'list'), 'grid');
    restored.dispose();
    await api.changes.close();
  });

  test('late loads cannot overwrite a new user or store session', () async {
    final api = _SessionApi();
    final repository = _MemoryRepository(api);
    repository.stored[api.scope] = {'calendar_layout': 'agenda'};
    repository.stored['other-user:other-store'] = {'calendar_layout': 'month'};
    final barrier = Completer<void>();
    repository.nextLoad = barrier;
    final provider = UiPreferencesProvider(repository: repository);
    api.switchSession('other-user:other-store');
    await _flush();
    expect(provider.value('calendar_layout', fallback: 'day'), 'month');
    barrier.complete();
    await _flush();
    expect(provider.value('calendar_layout', fallback: 'day'), 'month');
    provider.dispose();
    await api.changes.close();
  });

  test('queued writes from a previous account never run under a new session',
      () async {
    final api = _SessionApi();
    final repository = _MemoryRepository(api);
    final provider = UiPreferencesProvider(repository: repository);
    await _flush();
    final barrier = Completer<void>();
    repository.nextSave = barrier;
    final first = provider.setValue('calendar_layout', 'agenda');
    final second = provider.setValue('employees_view', 'grid');
    await _flush();
    api.switchSession('other-user:other-store');
    await _flush();
    barrier.complete();
    await Future.wait([first, second]);
    expect(repository.writes.length, 1);
    expect(repository.stored['other-user:other-store'], isNull);
    expect(provider.value('calendar_layout', fallback: 'day'), 'day');
    provider.dispose();
    await api.changes.close();
  });
}
