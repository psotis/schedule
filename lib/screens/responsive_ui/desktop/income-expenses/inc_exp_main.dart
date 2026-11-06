import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/app_timestamp.dart';
import 'package:scheldule/models/expenses.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';

class IncExpMain extends StatefulWidget {
  const IncExpMain({super.key});

  @override
  State<IncExpMain> createState() => _IncExpMainState();
}

class _IncExpMainState extends State<IncExpMain> {
  bool _loading = true;
  bool _saving = false;
  bool _dayLoading = false;
  String? _loadError;
  String? _monthError;
  int _monthRequest = 0;
  int _dayRequest = 0;
  TransactionType? _filterType;
  final Set<String> _deleting = {};
  final GlobalKey _entryFormKey = GlobalKey();

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
  StreamSubscription<void>? _transactionChanges;

  @override
  void initState() {
    super.initState();
    _transactionChanges = context
        .read<TransactionRepository>()
        .changes
        .listen((_) => _refreshTransactions());
    _bootstrap();
  }

  @override
  void dispose() {
    _transactionChanges?.cancel();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshTransactions() async {
    if (!mounted) return;
    await Future.wait([
      _loadMonth(),
      _loadByDay(_selectedDay),
    ]);
  }

  double get _monthlyIncome =>
      AppTransaction.totalForType(_monthTx, TransactionType.income);

  double get _monthlyExpense =>
      AppTransaction.totalForType(_monthTx, TransactionType.expense);

  double get _monthlyNet => AppTransaction.netTotal(_monthTx);

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
    if (!mounted) return;
    final request = ++_monthRequest;
    setState(() {
      _monthLoading = true;
      _monthError = null;
    });
    try {
      final transactions = await context
          .read<TransactionRepository>()
          .getTransactionsByMonth(year: _year, month: _month);
      if (!mounted || request != _monthRequest) return;
      setState(() => _monthTx = transactions);
    } catch (_) {
      if (!mounted || request != _monthRequest) return;
      setState(() => _monthError = 'Δεν φορτώθηκαν οι κινήσεις του μήνα.');
    } finally {
      if (mounted && request == _monthRequest) {
        setState(() => _monthLoading = false);
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _loadLookup();
      if (!mounted) return;
      await _refreshTransactions();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _loadError = 'Δεν φορτώθηκαν τα οικονομικά. Προσπαθήστε ξανά.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _loadLookup() async {
    final settings = Map<String, dynamic>.from(
      await context.read<ApiClient>().get('/finance/settings') as Map,
    );
    final data = Map<String, dynamic>.from(settings['lookup'] as Map);

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

  Future<void> _loadByDay(DateTime day) async {
    if (!mounted) return;
    final request = ++_dayRequest;
    setState(() => _dayLoading = true);
    final transactions =
        await context.read<TransactionRepository>().getByDay(day: day);
    if (!mounted || request != _dayRequest) return;
    setState(() {
      _todayTx = transactions;
      _dayLoading = false;
    });
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

  double get _incomeTotal =>
      AppTransaction.totalForType(_todayTx, TransactionType.income);

  double get _expenseTotal =>
      AppTransaction.totalForType(_todayTx, TransactionType.expense);

  double get _netTotal => AppTransaction.netTotal(_todayTx);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _selectedDay = picked);
    await _loadByDay(_selectedDay);
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
    if (_saving) return;
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

    if (!amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Συμπληρώστε ένα ποσό μεγαλύτερο από το μηδέν.')),
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

    setState(() => _saving = true);
    try {
      final saved =
          await context.read<TransactionRepository>().addTransaction(tx: tx);
      if (!saved) throw Exception('Transaction was not saved');
      if (!mounted) return;

      _amountCtrl.clear();
      _descCtrl.clear();

      await _refreshTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Η κίνηση αποθηκεύτηκε.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Αποτυχία αποθήκευσης')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _money(double value) => NumberFormat.currency(
        locale: 'el_GR',
        symbol: '€',
        decimalDigits: 2,
      ).format(value);

  String get _dayTitle =>
      '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}';

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      if (_type == TransactionType.expense) {
        final subs = expenseSubcategories[_expenseCategoryId] ?? const [];
        if (!subs.any((entry) => entry['id'] == _expenseSubcategoryId)) {
          _expenseSubcategoryId = _firstId(subs);
        }
      }
    });
  }

  Future<bool> _confirmDelete(AppTransaction transaction) async {
    return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Διαγραφή κίνησης'),
                  content: Text(
                      'Να διαγραφεί η κίνηση ${_money(transaction.amount)};'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Ακύρωση')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError),
                        child: const Text('Διαγραφή')),
                  ],
                )) ??
        false;
  }

  Future<void> _deleteTransaction(AppTransaction transaction) async {
    if (_deleting.contains(transaction.id)) return;
    setState(() {
      _deleting.add(transaction.id);
      _todayTx.removeWhere((entry) => entry.id == transaction.id);
    });
    final deleted = await context
        .read<TransactionRepository>()
        .deleteTransaction(txId: transaction.id);
    if (!mounted) return;
    await _refreshTransactions();
    if (!mounted) return;
    setState(() => _deleting.remove(transaction.id));
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Η κίνηση δεν διαγράφηκε.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Οικονομικά'),
        actions: [
          IconButton(
            tooltip: 'Νέα κίνηση',
            onPressed: _loading || _loadError != null
                ? null
                : () {
                    final formContext = _entryFormKey.currentContext;
                    if (formContext != null) {
                      Scrollable.ensureVisible(formContext,
                          duration: const Duration(milliseconds: 250),
                          alignment: 0.05);
                    }
                  },
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
              tooltip: 'Ανανέωση',
              onPressed: _loading || _saving ? null : _refreshTransactions,
              icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 36, color: colors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _bootstrap,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Δοκιμή ξανά')),
                      ])))
              : LayoutBuilder(builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final padding = compact ? 16.0 : 28.0;
                  return RefreshIndicator(
                    onRefresh: _refreshTransactions,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(padding, 12, padding,
                          24 + MediaQuery.paddingOf(context).bottom),
                      children: [
                        Center(
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1440),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _monthOverview(),
                                      const SizedBox(height: 24),
                                      if (constraints.maxWidth >= 1050)
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                  flex: 3,
                                                  child: _dayActivity()),
                                              const SizedBox(width: 24),
                                              Expanded(
                                                  flex: 2, child: _entryForm()),
                                            ])
                                      else ...[
                                        _dayActivity(),
                                        const SizedBox(height: 20),
                                        _entryForm(),
                                      ],
                                    ]))),
                      ],
                    ),
                  );
                }),
    );
  }

  Widget _monthOverview() {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Εικόνα του μήνα',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Έσοδα, έξοδα και καθαρό υπόλοιπο',
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ]),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outlineVariant)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: 'Προηγούμενος μήνας',
                      onPressed: _monthLoading ? null : _prevMonth,
                      icon: const Icon(Icons.chevron_left_rounded)),
                  Text(_monthTitle(_year, _month),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                      tooltip: 'Επόμενος μήνας',
                      onPressed: _monthLoading ? null : _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded)),
                ])),
          ]),
      const SizedBox(height: 18),
      if (_monthError != null)
        _FinancePanel(
            child: Row(children: [
          Expanded(
              child: Text(_monthError!, style: TextStyle(color: colors.error))),
          IconButton(
              tooltip: 'Δοκιμή ξανά',
              onPressed: _loadMonth,
              icon: const Icon(Icons.refresh_rounded)),
        ]))
      else
        LayoutBuilder(builder: (context, constraints) {
          final income = _FinanceMetric(
              label: 'Έσοδα',
              value: _money(_monthlyIncome),
              icon: Icons.south_west_rounded,
              accent: colors.primary,
              loading: _monthLoading);
          final expense = _FinanceMetric(
              label: 'Έξοδα',
              value: _money(_monthlyExpense),
              icon: Icons.north_east_rounded,
              accent: colors.error,
              loading: _monthLoading);
          final net = _FinanceMetric(
              label: 'Καθαρό υπόλοιπο',
              value: _money(_monthlyNet),
              icon: Icons.account_balance_wallet_outlined,
              accent: colors.primary,
              prominent: true,
              loading: _monthLoading);
          if (constraints.maxWidth < 650) {
            return Column(children: [
              net,
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: income),
                const SizedBox(width: 12),
                Expanded(child: expense),
              ])
            ]);
          }
          return Row(children: [
            Expanded(child: income),
            const SizedBox(width: 16),
            Expanded(child: expense),
            const SizedBox(width: 16),
            Expanded(child: net)
          ]);
        }),
    ]);
  }

  Widget _dayActivity() {
    final colors = Theme.of(context).colorScheme;
    final visible = _todayTx
        .where((entry) => _filterType == null || entry.type == _filterType)
        .toList();
    return _FinancePanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 12,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Κινήσεις ημέρας',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${_todayTx.length} κινήσεις · $_dayTitle',
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ]),
            OutlinedButton.icon(
                onPressed: _dayLoading || _saving ? null : _pickDay,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: const Text('Ημερομηνία')),
          ]),
      const SizedBox(height: 18),
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14)),
          child: LayoutBuilder(builder: (context, constraints) {
            final stats = [
              _dayMetric('Έσοδα ημέρας', _incomeTotal, colors.primary),
              _dayMetric('Έξοδα ημέρας', _expenseTotal, colors.error),
              _dayMetric('Καθαρό ημέρας', _netTotal, colors.onSurface),
            ];
            if (constraints.maxWidth < 380) {
              return Column(spacing: 12, children: [
                _dayMetric('Έσοδα ημέρας', _incomeTotal, colors.primary,
                    inline: true),
                _dayMetric('Έξοδα ημέρας', _expenseTotal, colors.error,
                    inline: true),
                _dayMetric('Καθαρό ημέρας', _netTotal, colors.onSurface,
                    inline: true),
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var index = 0; index < stats.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: stats[index]),
              ],
            ]);
          })),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: const Text('Όλες'),
            selected: _filterType == null,
            onSelected: (_) => setState(() => _filterType = null)),
        ChoiceChip(
            label: const Text('Έσοδα'),
            selected: _filterType == TransactionType.income,
            onSelected: (_) =>
                setState(() => _filterType = TransactionType.income)),
        ChoiceChip(
            label: const Text('Έξοδα'),
            selected: _filterType == TransactionType.expense,
            onSelected: (_) =>
                setState(() => _filterType = TransactionType.expense)),
      ]),
      const SizedBox(height: 12),
      if (_dayLoading)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()))
      else if (visible.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
            child: Column(children: [
              Icon(Icons.receipt_long_outlined,
                  size: 36, color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                  _todayTx.isEmpty
                      ? 'Δεν υπάρχουν κινήσεις για αυτή την ημέρα.'
                      : 'Δεν υπάρχουν κινήσεις με αυτό το φίλτρο.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ]))
      else
        ...visible.map(_transactionTile),
    ]));
  }

  Widget _dayMetric(String label, double amount, Color color,
      {bool inline = false}) {
    final heading = Text(label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    final value = Text(_dayLoading ? '—' : _money(amount),
        style:
            TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 17));
    if (inline) {
      return Row(children: [
        Expanded(child: heading),
        const SizedBox(width: 12),
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: value)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading,
      const SizedBox(height: 4),
      value,
    ]);
  }

  Widget _transactionTile(AppTransaction transaction) {
    final colors = Theme.of(context).colorScheme;
    final income = transaction.type == TransactionType.income;
    final accent = income ? colors.primary : colors.error;
    final category = _labelFor(
        income ? incomeCategories : expenseCategories, transaction.category);
    final details = <String>[
      if (!income && (transaction.subcategory ?? '').isNotEmpty)
        _subLabel(transaction.category, transaction.subcategory!),
      if (transaction.paymentMethod != null)
        _labelFor(paymentMethods, transaction.paymentMethod!.name),
      if (transaction.appointmentType != null)
        _labelFor(appointmentTypes, transaction.appointmentType!.name),
      if (transaction.description.isNotEmpty) transaction.description,
    ];
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _confirmDelete(transaction),
      onDismissed: (_) => _deleteTransaction(transaction),
      background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.delete_outline_rounded,
              color: colors.onErrorContainer)),
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
          decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant.withAlpha(120)),
              borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(
                    income
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: accent,
                    size: 18)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Text(income ? 'Έσοδο' : 'Έξοδο',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(category,
                        style: TextStyle(color: colors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 5),
                  Text('${income ? '+' : '−'} ${_money(transaction.amount)}',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(details.join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ])),
            IconButton(
                tooltip: 'Διαγραφή κίνησης',
                onPressed: _deleting.contains(transaction.id)
                    ? null
                    : () async {
                        if (await _confirmDelete(transaction) && mounted) {
                          await _deleteTransaction(transaction);
                        }
                      },
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: colors.onSurfaceVariant)),
          ])),
    );
  }

  Widget _entryForm() {
    final colors = Theme.of(context).colorScheme;
    final income = _type == TransactionType.income;
    return _FinancePanel(
        key: _entryFormKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Νέα κίνηση', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Καταχώρηση για $_dayTitle',
              style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 20),
          AbsorbPointer(
              absorbing: _saving,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<TransactionType>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: TransactionType.income,
                              label: Text('Έσοδο'),
                              icon: Icon(Icons.add_rounded)),
                          ButtonSegment(
                              value: TransactionType.expense,
                              label: Text('Έξοδο'),
                              icon: Icon(Icons.remove_rounded)),
                        ],
                        selected: {_type},
                        onSelectionChanged: (values) =>
                            _changeType(values.first)),
                    const SizedBox(height: 20),
                    TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                            labelText: 'Ποσό',
                            hintText: '0,00',
                            prefixIcon: Icon(Icons.euro_rounded))),
                    const SizedBox(height: 18),
                    if (income) ...[
                      _lookupField(
                          label: 'Κατηγορία εσόδου',
                          value: _incomeCategoryId,
                          entries: incomeCategories,
                          onChanged: (value) =>
                              setState(() => _incomeCategoryId = value)),
                      const SizedBox(height: 18),
                      _lookupField(
                          label: 'Τύπος ραντεβού',
                          value: _appointmentTypeId,
                          entries: appointmentTypes,
                          onChanged: (value) =>
                              setState(() => _appointmentTypeId = value)),
                    ] else ...[
                      _lookupField(
                          label: 'Κατηγορία εξόδου',
                          value: _expenseCategoryId,
                          entries: expenseCategories,
                          onChanged: (value) => setState(() {
                                _expenseCategoryId = value;
                                _expenseSubcategoryId = _firstId(
                                    expenseSubcategories[value] ?? const []);
                              })),
                      const SizedBox(height: 18),
                      _lookupField(
                          label: 'Υποκατηγορία',
                          value: _expenseSubcategoryId,
                          entries: expenseSubcategories[_expenseCategoryId] ??
                              const [],
                          onChanged: (value) =>
                              setState(() => _expenseSubcategoryId = value)),
                    ],
                    const SizedBox(height: 18),
                    _lookupField(
                        label: 'Τρόπος πληρωμής',
                        value: _paymentMethodId,
                        entries: paymentMethods,
                        onChanged: (value) =>
                            setState(() => _paymentMethodId = value)),
                    const SizedBox(height: 18),
                    TextField(
                        controller: _descCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            labelText: 'Περιγραφή (προαιρετικό)',
                            alignLabelWithHint: true)),
                  ])),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? 'Αποθήκευση…' : 'Αποθήκευση κίνησης')),
        ]));
  }

  Widget _lookupField(
      {required String label,
      required String value,
      required List<Map<String, dynamic>> entries,
      required ValueChanged<String> onChanged}) {
    return DropdownButtonFormField<String>(
      key: ValueKey(
          '$label:$value:${entries.map((entry) => entry['id']).join(',')}'),
      initialValue: entries.any((entry) => entry['id'] == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: entries
          .map((entry) => DropdownMenuItem<String>(
              value: entry['id'] as String,
              child: Text(entry['label'] as String,
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (selected) => onChanged(selected ?? ''),
    );
  }
}

class _FinancePanel extends StatelessWidget {
  final Widget child;
  const _FinancePanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withAlpha(140))),
        child: child,
      );
}

class _FinanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool prominent;
  final bool loading;
  const _FinanceMetric(
      {required this.label,
      required this.value,
      required this.icon,
      required this.accent,
      this.prominent = false,
      this.loading = false});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: prominent ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: prominent
                    ? colors.primary.withAlpha(50)
                    : colors.outlineVariant.withAlpha(140))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon,
              size: 22, color: prominent ? colors.onPrimaryContainer : accent),
          const SizedBox(height: 18),
          Text(label,
              style: TextStyle(
                  color: prominent
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontSize: 13)),
          const SizedBox(height: 6),
          SizedBox(
              height: 34,
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(loading ? '—' : value,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: prominent
                              ? colors.onPrimaryContainer
                              : colors.onSurface)))),
        ]));
  }
}
