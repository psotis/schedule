import 'package:scheldule/models/expenses.dart';
import 'api_client.dart';

class TransactionRepository {
  final ApiClient apiClient;

  TransactionRepository({required this.apiClient});

  Stream<void> get changes => apiClient.watch('transactions');

  Future<bool> hasFinancePin() async {
    final data = Map<String, dynamic>.from(
      await apiClient.get('/finance/access') as Map,
    );
    return data['has_pin'] == true;
  }

  Future<void> setFinancePin({
    required String currentPassword,
    required String pin,
  }) async {
    await apiClient.put('/finance/access/pin', body: {
      'current_password': currentPassword,
      'pin': pin,
    });
  }

  Future<void> verifyFinancePin(String pin) async {
    await apiClient.post('/finance/access/verify', body: {'pin': pin});
  }

  Future<bool> addTransaction({
    required AppTransaction tx,
  }) async {
    try {
      await apiClient.post('/transactions', body: tx.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTransaction({
    required AppTransaction tx,
  }) async {
    try {
      await apiClient.put('/transactions/${tx.id}', body: tx.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction({
    required String txId,
  }) async {
    try {
      await apiClient.delete('/transactions/$txId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AppTransaction>> getByDay({
    required DateTime day,
  }) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day + 1);

      final data = await apiClient.get('/transactions', query: {
        'from': start.toUtc().toIso8601String(),
        'to': end.toUtc().toIso8601String(),
      }) as List;
      return data
          .map((item) =>
              AppTransaction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  DateTime monthStart(int year, int month) {
    return DateTime(year, month, 1);
  }

  DateTime monthEnd(int year, int month) {
    return (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
  }

  Future<List<AppTransaction>> getTransactionsByMonth({
    required int year,
    required int month,
  }) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);

    final data = await apiClient.get('/transactions', query: {
      'from': start.toUtc().toIso8601String(),
      'to': end.toUtc().toIso8601String(),
    }) as List;
    return data
        .map((item) => AppTransaction.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
