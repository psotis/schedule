import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final double amount;
  final Timestamp date;
  final String description;

  const Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
  });

  /// INITIAL (used for state reset / editing)
  factory Expense.initial() {
    return Expense(
      id: '',
      amount: 0.0,
      date: Timestamp.fromDate(DateTime.now()),
      description: '',
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    Timestamp? date,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date,
      'description': description,
    };
  }

  static Expense fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Expense(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      date: data['date'] as Timestamp,
      description: (data['description'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, amount, date, description];
}
