import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

enum PaymentMethod { card, cash, iris, other }

enum AppointmentType { katoikon, grafeio, other }

class AppTransaction extends Equatable {
  final String id;

  final TransactionType type;
  final double amount;
  final Timestamp date;

  /// For expenses: category = pswnia / xwrou / ypallhloi / genika / mhniaia / loipa
  /// For income: category = eopyy (or idiwths if you want)
  final String category;

  /// For expenses: subcategory = market / rent / plhrwmh_mhna / efka / leasing ...
  /// For income: can be null (or use for extra)
  final String? subcategory;

  /// Income only
  final AppointmentType? appointmentType;

  /// Income mostly (but could also be used in expenses if you want vendor)
  final String? counterparty;

  /// Both
  final PaymentMethod? paymentMethod;

  final String description;

  const AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory,
    this.appointmentType,
    this.counterparty,
    this.paymentMethod,
    required this.description,
  });

  factory AppTransaction.initial() {
    return AppTransaction(
      id: '',
      type: TransactionType.expense,
      amount: 0.0,
      date: Timestamp.fromDate(DateTime.now()),
      category: '',
      subcategory: null,
      appointmentType: null,
      counterparty: null,
      paymentMethod: null,
      description: '',
    );
  }

  AppTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    Timestamp? date,
    String? category,
    String? subcategory,
    AppointmentType? appointmentType,
    String? counterparty,
    PaymentMethod? paymentMethod,
    String? description,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      appointmentType: appointmentType ?? this.appointmentType,
      counterparty: counterparty ?? this.counterparty,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount,
      'date': date,
      'category': category,
      'subcategory': subcategory,
      'appointmentType': appointmentType?.name,
      'counterparty': counterparty,
      'paymentMethod': paymentMethod?.name,
      'description': description,
    };
  }

  static AppTransaction fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppTransaction(
      id: doc.id,
      type: _parseType(data['type'] as String?),
      amount: (data['amount'] as num).toDouble(),
      date: data['date'] as Timestamp,
      category: (data['category'] as String?) ?? '',
      subcategory: data['subcategory'] as String?,
      appointmentType:
          _parseAppointmentType(data['appointmentType'] as String?),
      counterparty: data['counterparty'] as String?,
      paymentMethod: _parsePaymentMethod(data['paymentMethod'] as String?),
      description: (data['description'] as String?) ?? '',
    );
  }

  static TransactionType _parseType(String? v) {
    return TransactionType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => TransactionType.expense,
    );
  }

  static PaymentMethod? _parsePaymentMethod(String? v) {
    if (v == null || v.isEmpty) return null;
    return PaymentMethod.values.firstWhere(
      (e) => e.name == v,
      orElse: () => PaymentMethod.other,
    );
  }

  static AppointmentType? _parseAppointmentType(String? v) {
    if (v == null || v.isEmpty) return null;
    return AppointmentType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => AppointmentType.other,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        date,
        category,
        subcategory,
        appointmentType,
        counterparty,
        paymentMethod,
        description,
      ];
}
