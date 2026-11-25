import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../repositories/store_repository.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider({required this.repository}) {
    _sessionChanges = repository.apiClient.sessionChanges.listen((_) {
      _typeCode = '';
      _revision = -1;
      notifyListeners();
      _loadIfSignedIn();
    });
    _storeChanges = repository.changes.listen((_) => refresh());
    _loadIfSignedIn();
  }

  final StoreRepository repository;
  late final StreamSubscription<int> _sessionChanges;
  late final StreamSubscription<void> _storeChanges;
  String _typeCode = '';
  int _revision = -1;
  int _request = 0;
  bool _disposed = false;

  bool get showMedicalFields =>
      _revision == repository.apiClient.sessionRevision &&
      const {'physiotherapy', 'medical_office'}.contains(_typeCode);

  void _loadIfSignedIn() {
    if (repository.apiClient.hasSession &&
        repository.apiClient.activeStoreId != null) {
      refresh();
    }
  }

  Future<void> refresh() async {
    final request = ++_request;
    final revision = repository.apiClient.sessionRevision;
    try {
      final store = await repository.getCurrentStore();
      if (_disposed ||
          request != _request ||
          revision != repository.apiClient.sessionRevision) {
        return;
      }
      final type = store['storeType'];
      _typeCode = type is Map ? (type['code'] ?? '').toString() : '';
      _revision = revision;
      notifyListeners();
    } catch (_) {
      // Keep confirmed settings for this session during transient failures.
      // A new/unknown store never displays medical fields by default.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _sessionChanges.cancel();
    _storeChanges.cancel();
    super.dispose();
  }
}
