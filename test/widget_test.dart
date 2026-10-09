import 'package:flutter_test/flutter_test.dart';
import 'package:scheldule/models/app_timestamp.dart';
import 'package:scheldule/models/app_user.dart';
import 'package:scheldule/models/expenses.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';

void main() {
  test('service user and timestamp models preserve API values', () {
    final user = AppUser.fromJson({
      'uuid': 'user-id',
      'email': 'owner@example.com',
      'display_name': 'Owner',
      'profile_image': '',
      'role': 'admin',
      'active_store_id': 'store-id',
    });
    final timestamp = Timestamp.fromJson('2026-10-07T10:30:00.000Z');

    expect(user.uid, 'user-id');
    expect(user.activeStoreId, 'store-id');
    expect(timestamp.toDate().toUtc().hour, 10);
  });

  test('finance totals separate income and expenses using currency cents', () {
    final transactions = [
      AppTransaction(
        id: 'income-1',
        type: TransactionType.income,
        amount: 0.1,
        date: Timestamp.fromDate(DateTime(2026, 10, 9)),
        category: '',
        description: '',
      ),
      AppTransaction(
        id: 'income-2',
        type: TransactionType.income,
        amount: 0.2,
        date: Timestamp.fromDate(DateTime(2026, 10, 9)),
        category: '',
        description: '',
      ),
      AppTransaction(
        id: 'expense-1',
        type: TransactionType.expense,
        amount: 0.1,
        date: Timestamp.fromDate(DateTime(2026, 10, 9)),
        category: '',
        description: '',
      ),
    ];

    final income =
        AppTransaction.totalForType(transactions, TransactionType.income);
    final expense =
        AppTransaction.totalForType(transactions, TransactionType.expense);

    expect(income, 0.30);
    expect(expense, 0.10);
    expect(AppTransaction.netTotal(transactions), 0.20);
  });

  test('monthly finance ranges include one calendar month', () {
    final repository = TransactionRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
    );

    expect(repository.monthStart(2026, 12), DateTime(2026, 12, 1));
    expect(repository.monthEnd(2026, 12), DateTime(2027, 1, 1));
    expect(repository.monthEnd(2028, 2), DateTime(2028, 3, 1));
  });
}
