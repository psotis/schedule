import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/expenses.dart';

class ExpenseRepository {
  QuerySnapshot<Map<String, dynamic>>? expenses;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// ADD
  Future<bool> addExpense({
    required String userUid,
    required double amount,
    required Timestamp date,
    required String description,
  }) async {
    try {
      // ✅ Always write under a fixed root collection
      await firestore
          .collection('users')
          .doc(userUid)
          .collection('expenses')
          .add({
        'amount': amount,
        'date': date,
        'description': description,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// UPDATE
  Future<bool> updateExpense({
    required String userUid,
    required Expense expense,
  }) async {
    try {
      await firestore
          .collection(userUid)
          .doc(expense.id)
          .update(expense.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DELETE
  Future<bool> deleteExpense({
    required String userUid,
    required String expenseId,
  }) async {
    try {
      await firestore.collection(userUid).doc(expenseId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// GET ALL
  Future<List<Expense>> getExpenses({
    required String userUid,
  }) async {
    try {
      final snapshot = await firestore
          .collection(userUid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map(Expense.fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  /// GET BY DAY (00:00 → 23:59)
  Future<List<Expense>> getExpensesByDay({
    required String userUid,
    required DateTime day,
  }) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await firestore
          .collection(userUid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(end),
          )
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map(Expense.fromDoc).toList();
    } catch (_) {
      return [];
    }
  }
}
