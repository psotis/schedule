import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../repositories/ui_preferences_repository.dart';

class UiPreferencesProvider extends ChangeNotifier {
  final UiPreferencesRepository repository;
  late final StreamSubscription<int> _sessionSubscription;
  Map<String, String> _values = {};
  Map<String, String> _confirmed = {};
  final Map<String, int> _versions = {};
  Future<void> _pending = Future.value();
  bool _disposed = false;
  bool loading = false;
  String? error;
  int _generation = 0;

  UiPreferencesProvider({required this.repository}) {
    _sessionSubscription = repository.apiClient.sessionChanges.listen((_) {
      _values = {};
      _confirmed = {};
      _versions.clear();
      error = null;
      _load();
      notifyListeners();
    });
    _load();
  }

  String value(String key, {required String fallback}) =>
      _values[key] ?? fallback;

  Future<void> _load() async {
    final generation = ++_generation;
    final api = repository.apiClient;
    if (!api.hasSession || api.activeStoreId == null) {
      loading = false;
      return;
    }
    loading = true;
    final revision = api.sessionRevision;
    try {
      final saved = await repository.load();
      if (_disposed ||
          generation != _generation ||
          revision != api.sessionRevision) {
        return;
      }
      // Choices made while the initial request was in flight take precedence.
      _confirmed = {...saved, ..._confirmed};
      _values = {...saved, ..._values};
    } catch (_) {
      if (_disposed ||
          generation != _generation ||
          revision != api.sessionRevision) {
        return;
      }
      error = 'Δεν φορτώθηκαν οι αποθηκευμένες προτιμήσεις.';
    }
    if (!_disposed &&
        generation == _generation &&
        revision == api.sessionRevision) {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> setValue(String key, String value) async {
    final generation = _generation;
    final revision = repository.apiClient.sessionRevision;
    final version = (_versions[key] ?? 0) + 1;
    _versions[key] = version;
    _values[key] = value;
    error = null;
    notifyListeners();
    var saved = false;
    // Serialize writes so rapid choices cannot arrive at the server out of order.
    final write = _pending.then((_) async {
      if (_disposed ||
          generation != _generation ||
          revision != repository.apiClient.sessionRevision) {
        return;
      }
      try {
        await repository.save(key, value);
        saved = true;
        if (!_disposed &&
            generation == _generation &&
            revision == repository.apiClient.sessionRevision) {
          _confirmed[key] = value;
        }
        if (!_disposed &&
            generation == _generation &&
            _versions[key] == version) {
          error = null;
          notifyListeners();
        }
      } catch (_) {
        if (_disposed ||
            generation != _generation ||
            _versions[key] != version) {
          return;
        }
        final previous = _confirmed[key];
        if (previous == null) {
          _values.remove(key);
        } else {
          _values[key] = previous;
        }
        error = 'Η προτίμηση δεν αποθηκεύτηκε. Προσπαθήστε ξανά.';
        notifyListeners();
      }
    });
    _pending = write;
    await write;
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionSubscription.cancel();
    super.dispose();
  }
}
