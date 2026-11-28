import 'customer_merge_dialog.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'customer_profile_form.dart';

class CustomerInsights extends StatefulWidget {
  final String customerId;
  final ValueChanged<String>? onMerged;

  const CustomerInsights({super.key, required this.customerId, this.onMerged});

  @override
  State<CustomerInsights> createState() => _CustomerInsightsState();
}

class _CustomerInsightsState extends State<CustomerInsights> {
  Map<String, dynamic>? _report;
  StreamSubscription<void>? _changes;
  StreamSubscription<Map<String, dynamic>>? _merges;

  @override
  void initState() {
    super.initState();
    _load();
    _merges = context.read<AppointmentRepository>().apiClient.mergeNotices.listen((notice) {
      if (notice['source_uuid'] != widget.customerId) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onMerged?.call(notice['target_uuid'].toString());
      });
    });
    _changes = context.read<AppointmentRepository>().changes.listen((_) {
      _load();
    });
  }

  Future<void> _load() async {
    try {
      final report = await context
          .read<AppointmentRepository>()
          .getClientReport(widget.customerId);
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted) setState(() => _report = const {});
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _merges?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    if (report == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (report.isEmpty) return const SizedBox.shrink();
    final totals = Map<String, dynamic>.from(
      (report['totals'] ?? const <String, dynamic>{}) as Map,
    );
    final history = ((report['history'] ?? const []) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final client = Map<String, dynamic>.from(
      (report['client'] ?? const <String, dynamic>{}) as Map,
    );
    final serviceCount = ((report['services'] ?? const []) as List).fold<int>(
      0,
      (sum, item) =>
          sum +
          (num.tryParse(
                Map<String, dynamic>.from(item as Map)['count'].toString(),
              )?.round() ??
              0),
    );
    return Card(
      margin: const EdgeInsets.all(12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.insights),
        title: const Text('Σύνοψη και ιστορικό πελάτη'),
        children: [
          if (const {'owner', 'admin'}.contains(context.watch<AuthProvider?>()?.state.user?.storeRole))
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(
              icon: const Icon(Icons.merge_type), label: const Text('Συγχώνευση καρτέλας'),
              onPressed: () async {
                final target = await showDialog<String>(context: context, barrierDismissible: false, builder: (_) => CustomerMergeDialog(source: client, apiClient: context.read<AppointmentRepository>().apiClient));
                if (!context.mounted || target == null) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Οι καρτέλες συγχωνεύτηκαν με διατήρηση ιστορικού.')));
                widget.onMerged?.call(target);
              },
            ))),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Βασικά στοιχεία πελάτη'),
                onPressed: () async {
                  await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                            child: SizedBox(
                              width: 600,
                              height:
                                  MediaQuery.sizeOf(dialogContext).height * .85,
                              child: Column(children: [
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        icon: const Icon(Icons.close))),
                                Expanded(
                                    child: CustomerProfileForm(
                                        customer: client,
                                        onSaved: () =>
                                            Navigator.pop(dialogContext))),
                              ]),
                            ),
                          ));
                  await _load();
                },
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _Value('Ραντεβού', totals['appointments'] ?? 0),
                _Value('Ολοκληρωμένα', totals['completed'] ?? 0),
                _Value('Υπηρεσίες', serviceCount),
                _Value('Αξία', totals['service_value'] ?? 0, money: true),
                _Value('Εισπράξεις', totals['collected'] ?? 0, money: true),
                _Value('Υπόλοιπο', totals['outstanding'] ?? 0, money: true),
                _Value(
                  'Μέση αξία',
                  totals['average_completed_appointment'] ?? 0,
                  money: true,
                ),
                _Value('Τελευταία επίσκεψη', _date(report['last_visit'])),
                _Value('Επόμενο ραντεβού', _date(report['next_appointment'])),
                _Value('Πρώτη επίσκεψη', _date(client['first_visit_at'])),
                if ((client['source'] ?? '').toString().isNotEmpty)
                  _Value('Πηγή', client['source']),
              ],
            ),
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Δεν υπάρχει ιστορικό ραντεβού.'),
            )
          else
            ...history.map(_historyTile),
          const Divider(),
          const ListTile(title: Text('Ανάλυση ανά υπηρεσία')),
          ...((report['services'] ?? const []) as List).map((value) {
            final service = Map<String, dynamic>.from(value as Map);
            return ListTile(
              title: Text(service['name'].toString()),
              subtitle: Text('${service['count']} υπηρεσίες'),
              trailing: Text('${_money(service['value'])} €'),
            );
          }),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> item) {
    final services = ((item['services'] ?? const []) as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    final serviceNames = services
        .map((service) => (service['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .join(', ');
    final employees = services
        .map((service) => (service['employee'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(', ');
    return ListTile(
      leading: const Icon(Icons.event_note),
      title: Text(serviceNames.isEmpty ? 'Ραντεβού' : serviceNames),
      subtitle: Text(
        [
          _date(item['start_time'], includeTime: true),
          _status(item['status']),
          employees,
        ].where((value) => value.isNotEmpty).join(' • '),
      ),
      trailing: Text(
        '${_money(item['paid'])} / ${_money(item['total_price'])} €',
      ),
    );
  }

  static String _date(dynamic value, {bool includeTime = false}) {
    final date = DateTime.tryParse((value ?? '').toString());
    if (date == null) return '-';
    return DateFormat(includeTime ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy')
        .format(date.toLocal());
  }

  static String _money(dynamic value) =>
      (num.tryParse(value.toString()) ?? 0).toStringAsFixed(2);

  static String _status(dynamic value) {
    const labels = {
      'scheduled': 'Προγραμματισμένο',
      'confirmed': 'Επιβεβαιωμένο',
      'arrived': 'Προσήλθε',
      'in_progress': 'Σε εξέλιξη',
      'completed': 'Ολοκληρωμένο',
      'cancelled': 'Ακυρωμένο',
      'no_show': 'Δεν προσήλθε',
    };
    return labels[value] ?? value?.toString() ?? '';
  }
}

class _Value extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool money;

  const _Value(this.label, this.value, {this.money = false});

  @override
  Widget build(BuildContext context) {
    final displayed = money
        ? '${(num.tryParse(value.toString()) ?? 0).toStringAsFixed(2)} €'
        : value.toString();
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(displayed, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
