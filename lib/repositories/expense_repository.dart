import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/expenses.dart';

class TransactionRepository {
  final FirebaseFirestore firestore;

  TransactionRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _txRef(String userUid) {
    return firestore
        .collection('users')
        .doc(userUid)
        .collection('transactions');
  }

  Future<bool> addTransaction({
    required String userUid,
    required AppTransaction tx,
  }) async {
    try {
      await _txRef(userUid).add(tx.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String userUid,
    required AppTransaction tx,
  }) async {
    try {
      await _txRef(userUid).doc(tx.id).update(tx.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction({
    required String userUid,
    required String txId,
  }) async {
    try {
      await _txRef(userUid).doc(txId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AppTransaction>> getByDay({
    required String userUid,
    required DateTime day,
  }) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await _txRef(userUid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map(AppTransaction.fromDoc).toList();
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
    required String uid,
    required int year,
    required int month,
  }) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(end),
        )
        .orderBy('date')
        .get();

    return snap.docs.map(AppTransaction.fromDoc).toList();
  }
}
