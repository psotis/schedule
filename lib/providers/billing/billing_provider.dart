import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../repositories/billing_repository.dart';

class BillingProvider extends ChangeNotifier {
  final BillingRepository repository;
  Map<String, dynamic>? data;
  String? error;
  bool loading = false;
  bool _disposed = false;
  int _request = 0;
  Timer? _expiry;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  BillingProvider({required this.repository}) {
    final api = repository.apiClient;
    _subscriptions.add(
      api.sessionChanges.listen((_) {
        data = null;
        _expiry?.cancel();
        load();
      }),
    );
    _subscriptions.add(api.watch('billing').listen((_) => load()));
    _subscriptions.add(
      api.accessRequired.listen((_) {
        data = null;
        load();
      }),
    );
    load();
  }

  bool get canManage => data?['can_manage'] == true;
  bool get allowed => data?['access_allowed'] == true;

  Future<void> load() async {
    final request = ++_request;
    final api = repository.apiClient;
    _expiry?.cancel();
    if (!api.hasSession || api.activeStoreId == null) {
      loading = false;
      data = null;
      error = null;
      if (!_disposed) notifyListeners();
      return;
    }
    final revision = api.sessionRevision;
    loading = true;
    if (!_disposed) notifyListeners();
    try {
      final status = await repository.status();
      if (_disposed || request != _request || revision != api.sessionRevision) {
        return;
      }
      data = status;
      error = null;
      final end = DateTime.tryParse('${status['expires_at'] ?? ''}');
      if (allowed && end != null && end.isAfter(DateTime.now())) {
        _scheduleAccessEvent(end);
      }
    } catch (failure) {
      if (_disposed || request != _request || revision != api.sessionRevision) {
        return;
      }
      error = failure.toString();
    }
    if (!_disposed && request == _request) {
      loading = false;
      notifyListeners();
    }
  }

  void _scheduleAccessEvent(DateTime end) {
    final now = DateTime.now();
    final next = [
      for (final days in [5, 3, 1, 0]) end.subtract(Duration(days: days))
    ].firstWhere((date) => date.isAfter(now), orElse: () => end);
    final delay = next.difference(now);
    // Intermediate clock events avoid browser timer overflow without polling.
    const maximumDelay = Duration(days: 20);
    if (delay > maximumDelay) {
      _expiry = Timer(maximumDelay, () => _scheduleAccessEvent(end));
    } else {
      _expiry = Timer(
          delay.isNegative ? Duration.zero : delay + const Duration(seconds: 1),
          load);
    }
  }

  Future<void> trial() async {
    await repository.startTrial();
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
