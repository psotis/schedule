import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scheldule/models/expenses.dart';
import 'package:scheldule/repositories/expense_repository.dart';

class ExpenseStateProvider extends ChangeNotifier {
  ExpenseStateProvider({
    required this.expenseRepository,
  });

  final ExpenseRepository expenseRepository;

  /// Current expense (form/edit)
  Expense _expense = Expense.initial();
  Expense get expense => _expense;

  /// Expenses for selected day
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// ---------------- STATE ----------------

  void resetExpense() {
    _expense = Expense.initial();
    notifyListeners();
  }

  void setExpense(Expense expense) {
    _expense = expense;
    notifyListeners();
  }

  void updateAmount(double value) {
    _expense = _expense.copyWith(amount: value);
    notifyListeners();
  }

  void updateDate(DateTime value) {
    _expense = _expense.copyWith(
      date: Timestamp.fromDate(value),
    );
    notifyListeners();
  }

  void updateDescription(String value) {
    _expense = _expense.copyWith(description: value);
    notifyListeners();
  }

  /// ---------------- FIRESTORE ----------------

  Future<void> fetchExpensesByDay(DateTime day, String userUid) async {
    _isLoading = true;
    notifyListeners();

    _expenses = await expenseRepository.getExpensesByDay(
      userUid: userUid,
      day: day,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveExpense(String userUid) async {
    _isLoading = true;
    notifyListeners();

    bool success;

    if (_expense.id.isEmpty) {
      success = await expenseRepository.addExpense(
        userUid: userUid,
        amount: _expense.amount,
        date: _expense.date,
        description: _expense.description,
      );
    } else {
      success = await expenseRepository.updateExpense(
        userUid: userUid,
        expense: _expense,
      );
    }

    if (success) {
      resetExpense();
      await fetchExpensesByDay(_expense.date.toDate(), userUid);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteExpense(String expenseId, String userUid) async {
    _isLoading = true;
    notifyListeners();

    final success = await expenseRepository.deleteExpense(
      userUid: userUid,
      expenseId: expenseId,
    );

    if (success) {
      _expenses.removeWhere((e) => e.id == expenseId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// ---------------- DAILY TOTAL ----------------
  /// Starts at 0, adds all expenses for the day
  double get dailyTotal {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
