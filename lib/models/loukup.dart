import 'package:cloud_firestore/cloud_firestore.dart';

class Lookup {
  final List<String> paymentMethods; // ["card","cash","iris"]
  final List<String> appointmentTypes; // ["katoikon","grafeio"]
  final List<Map<String, dynamic>> expenseCategories; // [{id,label,sort}]
  final Map<String, List<Map<String, dynamic>>>
      expenseSubcategories; // by categoryId
  final List<Map<String, dynamic>> incomeCategories; // [{id,label,sort}]

  Lookup({
    required this.paymentMethods,
    required this.appointmentTypes,
    required this.expenseCategories,
    required this.expenseSubcategories,
    required this.incomeCategories,
  });

  Map<String, dynamic> toMap() => {
        'paymentMethods': paymentMethods,
        'appointmentTypes': appointmentTypes,
        'expenseCategories': expenseCategories,
        'expenseSubcategories': expenseSubcategories,
        'incomeCategories': incomeCategories,
      };

  static Lookup fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Lookup(
      paymentMethods: List<String>.from(data['paymentMethods'] ?? []),
      appointmentTypes: List<String>.from(data['appointmentTypes'] ?? []),
      expenseCategories:
          List<Map<String, dynamic>>.from(data['expenseCategories'] ?? []),
      expenseSubcategories:
          (data['expenseSubcategories'] as Map<String, dynamic>? ?? {}).map(
              (k, v) =>
                  MapEntry(k, List<Map<String, dynamic>>.from(v as List))),
      incomeCategories:
          List<Map<String, dynamic>>.from(data['incomeCategories'] ?? []),
    );
  }
}
