import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/models/expenses.dart';
import 'package:scheldule/repositories/expense_repository.dart';

class TransactionStateProvider extends ChangeNotifier {
  TransactionStateProvider({required this.repository});

  final TransactionRepository repository;

  AppTransaction _tx = AppTransaction.initial();
  AppTransaction get tx => _tx;

  List<AppTransaction> _txs = [];
  List<AppTransaction> get txs => _txs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void reset() {
    _tx = AppTransaction.initial();
    notifyListeners();
  }

  void setTx(AppTransaction value) {
    _tx = value;
    notifyListeners();
  }

  void updateType(TransactionType type) {
    // when switching type, clear fields that don’t apply
    if (type == TransactionType.income) {
      _tx = _tx.copyWith(
        type: type,
        category: 'eopyy', // optional default
        subcategory: null,
      );
    } else {
      _tx = _tx.copyWith(
        type: type,
        appointmentType: null,
        counterparty: null,
      );
    }
    notifyListeners();
  }

  void updatePaymentMethod(PaymentMethod? method) {
    _tx = _tx.copyWith(paymentMethod: method);
    notifyListeners();
  }

  void updateAppointmentType(AppointmentType? value) {
    _tx = _tx.copyWith(appointmentType: value);
    notifyListeners();
  }

  void updateCategory(String value) {
    // when category changes, reset subcategory
    _tx = _tx.copyWith(category: value, subcategory: null);
    notifyListeners();
  }

  void updateSubcategory(String? value) {
    _tx = _tx.copyWith(subcategory: value);
    notifyListeners();
  }

  void updateAmount(double value) {
    _tx = _tx.copyWith(amount: value);
    notifyListeners();
  }

  void updateDate(DateTime value) {
    _tx = _tx.copyWith(date: Timestamp.fromDate(value));
    notifyListeners();
  }

  void updateDescription(String value) {
    _tx = _tx.copyWith(description: value);
    notifyListeners();
  }

  Future<void> fetchByDay(DateTime day, String userUid) async {
    _isLoading = true;
    notifyListeners();

    _txs = await repository.getByDay(userUid: userUid, day: day);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> save(String userUid) async {
    _isLoading = true;
    notifyListeners();

    final bool success = _tx.id.isEmpty
        ? await repository.addTransaction(userUid: userUid, tx: _tx)
        : await repository.updateTransaction(userUid: userUid, tx: _tx);

    if (success) {
      final day = _tx.date.toDate();
      reset();
      await fetchByDay(day, userUid);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> delete(String txId, String userUid) async {
    _isLoading = true;
    notifyListeners();

    final success =
        await repository.deleteTransaction(userUid: userUid, txId: txId);
    if (success) {
      _txs.removeWhere((t) => t.id == txId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  double get dailyTotal {
    return _txs.fold(
        0.0,
        // ignore: avoid_types_as_parameter_names
        (sum, t) => sum + (t.type == TransactionType.expense ? t.amount : 0.0));
  }

  double get dailyIncome {
    return _txs.fold(
        0.0,
        // ignore: avoid_types_as_parameter_names
        (sum, t) => sum + (t.type == TransactionType.income ? t.amount : 0.0));
  }
}
