import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/models/expenses.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/repositories/setup.dart';

class IncExpMain extends StatefulWidget {
  final User? user;
  const IncExpMain({super.key, this.user});

  @override
  State<IncExpMain> createState() => _IncExpMainState();
}

class _IncExpMainState extends State<IncExpMain> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;

  // ---------------- LOOKUP (dropdown values) ----------------
  List<Map<String, dynamic>> paymentMethods = []; // [{id,label}]
  List<Map<String, dynamic>> appointmentTypes = []; // [{id,label}]
  List<Map<String, dynamic>> incomeCategories = []; // [{id,label,sort}]
  List<Map<String, dynamic>> expenseCategories = []; // [{id,label,sort}]
  Map<String, List<Map<String, dynamic>>> expenseSubcategories =
      {}; // {catId: [{id,label,sort}]}

  // ---------------- FORM STATE ----------------
  TransactionType _type = TransactionType.expense;

  // selected IDs ("" = empty option)
  String _paymentMethodId = "";
  String _appointmentTypeId = "";

  String _incomeCategoryId = "";
  String _expenseCategoryId = "";
  String _expenseSubcategoryId = "";

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  DateTime _selectedDay = DateTime.now();

  // ---------------- LIST ----------------
  List<AppTransaction> _todayTx = [];
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  bool _monthLoading = false;
  List<AppTransaction> _monthTx = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _monthlyIncome => _monthTx.fold(
        0.0,
        (s, t) => s + (t.type == TransactionType.income ? t.amount : 0.0),
      );

  double get _monthlyExpense => _monthTx.fold(
        0.0,
        (s, t) => s + (t.type == TransactionType.expense ? t.amount : 0.0),
      );

  String _monthTitle(int y, int m) {
    const months = [
      '',
      'Ιανουάριος',
      'Φεβρουάριος',
      'Μάρτιος',
      'Απρίλιος',
      'Μάιος',
      'Ιούνιος',
      'Ιούλιος',
      'Αύγουστος',
      'Σεπτέμβριος',
      'Οκτώβριος',
      'Νοέμβριος',
      'Δεκέμβριος'
    ];
    return '${months[m]} $y';
  }

  Future<void> _loadMonth() async {
    final uid = widget.user?.uid;
    if (uid == null) return;

    setState(() => _monthLoading = true);

    _monthTx = await TransactionRepository()
        .getTransactionsByMonth(uid: uid, year: _year, month: _month);

    setState(() => _monthLoading = false);
  }

  Future<void> _bootstrap() async {
    final uid = widget.user?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    // 1) seed lookup once (if missing)
    await AppSetupService(firestore: _firestore).seedLookupIfNeeded(uid);

    // 2) load lookup doc
    await _loadLookup(uid);

    await _loadMonth();
    // 3) load today's transactions
    await _loadByDay(uid, _selectedDay);

    setState(() => _loading = false);
  }

  Future<void> _prevMonth() async {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
    await _loadMonth();
  }

  Future<void> _nextMonth() async {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
    await _loadMonth();
  }

  Future<void> _loadLookup(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('lookup')
        .get();

    final data = (doc.data() ?? defaultLookupData);

    paymentMethods =
        List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []);
    appointmentTypes =
        List<Map<String, dynamic>>.from(data['appointmentTypes'] ?? []);
    incomeCategories =
        List<Map<String, dynamic>>.from(data['incomeCategories'] ?? []);
    expenseCategories =
        List<Map<String, dynamic>>.from(data['expenseCategories'] ?? []);

    final rawSubs =
        (data['expenseSubcategories'] as Map<String, dynamic>? ?? {});
    expenseSubcategories = rawSubs.map(
      (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)),
    );

    // defaults: choose first item's id (usually "" because you added empty option)
    _paymentMethodId = _firstId(paymentMethods);
    _appointmentTypeId = _firstId(appointmentTypes);
    _incomeCategoryId = _firstId(incomeCategories);
    _expenseCategoryId = _firstId(expenseCategories);

    // subcategory depends on category
    final subs = expenseSubcategories[_expenseCategoryId] ?? const [];
    _expenseSubcategoryId = _firstId(subs);
  }

  String _firstId(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return "";
    final v = list.first['id'];
    return (v is String) ? v : "";
  }

  Future<void> _loadByDay(String uid, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    _todayTx = snap.docs.map(AppTransaction.fromDoc).toList();
  }

  String _labelFor(List<Map<String, dynamic>> list, String id) {
    final found = list.where((e) => e['id'] == id);
    if (found.isEmpty) return id.isEmpty ? "—" : id;
    return (found.first['label'] as String?) ?? (id.isEmpty ? "—" : id);
  }

  String _subLabel(String catId, String subId) {
    final list = expenseSubcategories[catId] ?? const [];
    final found = list.where((e) => e['id'] == subId);
    if (found.isEmpty) return subId.isEmpty ? "—" : subId;
    return (found.first['label'] as String?) ?? (subId.isEmpty ? "—" : subId);
  }

  double get _incomeTotal => _todayTx.fold(
        0.0,
        (s, t) => s + (t.type == TransactionType.income ? t.amount : 0.0),
      );

  double get _expenseTotal => _todayTx.fold(
        0.0,
        (s, t) => s + (t.type == TransactionType.expense ? t.amount : 0.0),
      );

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final uid = widget.user?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    _selectedDay = picked;
    await _loadByDay(uid, _selectedDay);
    setState(() => _loading = false);
  }

  PaymentMethod? _toPaymentMethod(String id) {
    if (id.isEmpty) return null;
    return PaymentMethod.values.firstWhere(
      (e) => e.name == id,
      orElse: () => PaymentMethod.other,
    );
  }

  AppointmentType? _toAppointmentType(String id) {
    if (id.isEmpty) return null;
    return AppointmentType.values.firstWhere(
      (e) => e.name == id,
      orElse: () => AppointmentType.other,
    );
  }

  Future<void> _save() async {
    final uid = widget.user?.uid;
    if (uid == null) return;

    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Βάλε ποσό > 0')),
      );
      return;
    }

    final isIncome = _type == TransactionType.income;

    // Category rules:
    // - income: allow empty category (""), or pick eopyy
    // - expense: allow empty, but you might enforce it later if you want
    final categoryId = isIncome ? _incomeCategoryId : _expenseCategoryId;

    // Subcategory only for expense
    final subcategoryId = isIncome ? null : _expenseSubcategoryId;

    final tx = AppTransaction(
      id: '',
      type: _type,
      amount: amount,
      date: Timestamp.fromDate(_selectedDay),
      category: categoryId,
      subcategory: subcategoryId,
      paymentMethod: _toPaymentMethod(_paymentMethodId),
      appointmentType: isIncome ? _toAppointmentType(_appointmentTypeId) : null,
      // optional: you can store counterparty too; leaving null unless you want always EOPYY for income
      counterparty: null,
      description: _descCtrl.text.trim(),
    );

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add(tx.toMap());

      _amountCtrl.clear();
      _descCtrl.clear();

      setState(() => _loading = true);
      await _loadByDay(uid, _selectedDay);
      setState(() => _loading = false);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Αποτυχία αποθήκευσης')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('No user')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Έσοδα / Έξοδα'),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _loading = true);
                await _loadByDay(uid, _selectedDay);
                setState(() => _loading = false);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _monthLoading ? null : _prevMonth,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text(
                                  _monthTitle(_year, _month),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: _monthLoading ? null : _nextMonth,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_monthLoading)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ))
                          else ...[
                            Text(
                                'Μηνιαία Έσοδα: ${_monthlyIncome.toStringAsFixed(2)}'),
                            Text(
                                'Μηνιαία Έξοδα: ${_monthlyExpense.toStringAsFixed(2)}'),
                            const Divider(),
                            Text(
                              'Μηνιαίο Καθαρό: ${(_monthlyIncome - _monthlyExpense).toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -------- Totals card --------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ημερομηνία: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text('Έσοδα: ${_incomeTotal.toStringAsFixed(2)}'),
                          Text('Έξοδα: ${_expenseTotal.toStringAsFixed(2)}'),
                          const Divider(),
                          Text(
                            'Καθαρό: ${(_incomeTotal - _expenseTotal).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // -------- Form card --------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<TransactionType>(
                            initialValue: _type,
                            items: const [
                              DropdownMenuItem(
                                value: TransactionType.income,
                                child: Text('Έσοδο'),
                              ),
                              DropdownMenuItem(
                                value: TransactionType.expense,
                                child: Text('Έξοδο'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _type = v;

                                // keep dropdowns stable when switching types
                                if (_type == TransactionType.expense) {
                                  // ensure subcategory is valid for current category
                                  final subs = expenseSubcategories[
                                          _expenseCategoryId] ??
                                      const [];
                                  if (subs.isNotEmpty) {
                                    final exists = subs.any((e) =>
                                        (e['id'] as String?) ==
                                        _expenseSubcategoryId);
                                    if (!exists) {
                                      _expenseSubcategoryId = _firstId(subs);
                                    }
                                  } else {
                                    _expenseSubcategoryId = "";
                                  }
                                }
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: 'Τύπος'),
                          ),

                          const SizedBox(height: 10),

                          // Income fields
                          if (_type == TransactionType.income) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _incomeCategoryId,
                              items: incomeCategories
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'] as String,
                                      child: Text(e['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _incomeCategoryId = v ?? ""),
                              decoration: const InputDecoration(
                                  labelText: 'Κατηγορία εσόδου'),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethodId,
                              items: paymentMethods
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'] as String,
                                      child: Text(e['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethodId = v ?? ""),
                              decoration: const InputDecoration(
                                  labelText: 'Τρόπος πληρωμής'),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _appointmentTypeId,
                              items: appointmentTypes
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'] as String,
                                      child: Text(e['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _appointmentTypeId = v ?? ""),
                              decoration: const InputDecoration(
                                  labelText: 'Τύπος ραντεβού'),
                            ),
                          ],

                          // Expense fields
                          if (_type == TransactionType.expense) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _expenseCategoryId,
                              items: expenseCategories
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'] as String,
                                      child: Text(e['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                final newCat = v ?? "";
                                final subs =
                                    expenseSubcategories[newCat] ?? const [];
                                setState(() {
                                  _expenseCategoryId = newCat;
                                  _expenseSubcategoryId = _firstId(subs);
                                });
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Κατηγορία εξόδου'),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _expenseSubcategoryId,
                              items:
                                  (expenseSubcategories[_expenseCategoryId] ??
                                          const [])
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e['id'] as String,
                                          child: Text(e['label'] as String),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(
                                  () => _expenseSubcategoryId = v ?? ""),
                              decoration: const InputDecoration(
                                  labelText: 'Υποκατηγορία'),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethodId,
                              items: paymentMethods
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e['id'] as String,
                                      child: Text(e['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethodId = v ?? ""),
                              decoration: const InputDecoration(
                                  labelText: 'Τρόπος πληρωμής'),
                            ),
                          ],

                          const SizedBox(height: 10),

                          TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Ποσό'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Περιγραφή (προαιρετικό)'),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
                              label: const Text('Αποθήκευση'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Κινήσεις ημέρας',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_todayTx.isEmpty)
                    const Text('Δεν υπάρχουν κινήσεις για αυτή την ημέρα.')
                  else
                    ..._todayTx.map((t) {
                      final isIncome = t.type == TransactionType.income;

                      final title = isIncome
                          ? 'Έσοδο • ${_labelFor(incomeCategories, t.category)}'
                          : 'Έξοδο • ${_labelFor(expenseCategories, t.category)} / ${_subLabel(t.category, t.subcategory ?? "")}';

                      final methodText =
                          t.paymentMethod == null ? "" : t.paymentMethod!.name;
                      final apptText = t.appointmentType == null
                          ? ""
                          : t.appointmentType!.name;

                      final subtitleParts = <String>[];
                      if (methodText.isNotEmpty)
                        subtitleParts.add('method: $methodText');
                      if (apptText.isNotEmpty)
                        subtitleParts.add('ραντεβού: $apptText');
                      if (t.description.isNotEmpty)
                        subtitleParts.add(t.description);

                      return Card(
                        child: ListTile(
                          leading: Icon(isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward),
                          title: Text(title),
                          subtitle: subtitleParts.isEmpty
                              ? null
                              : Text(subtitleParts.join(' • ')),
                          trailing: Text(t.amount.toStringAsFixed(2)),
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
