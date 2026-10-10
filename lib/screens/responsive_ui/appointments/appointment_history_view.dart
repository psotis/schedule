import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/appointment/appointment_status.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';

class AppointmentHistoryView extends StatefulWidget {
  const AppointmentHistoryView({super.key});

  @override
  State<AppointmentHistoryView> createState() => _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<AppointmentHistoryView> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context
      .read<AppointmentProvider>()
      .getAppointMentsByDate(date: _selectedDate);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('el'),
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2070),
    );
    if (date == null) return;
    setState(() => _selectedDate = date);
    await _refresh();
  }

  Future<void> _changeStatus(AppointMent appointment, String status) async {
    if (status == 'completed') {
      await _completeAppointment(appointment);
      return;
    }
    try {
      await context.read<AppointmentRepository>().updateStatus(
            appointment: appointment,
            status: status,
          );
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _completeAppointment(AppointMent appointment) async {
    final paid = appointment.payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final outstanding =
        (appointment.totalPrice - paid).clamp(0, double.infinity);
    if (outstanding == 0) {
      try {
        await context.read<AppointmentRepository>().updateStatus(
              appointment: appointment,
              status: 'completed',
            );
        await _refresh();
      } catch (error) {
        _showError(error);
      }
      return;
    }
    final payment = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(
        amount: outstanding.toDouble(),
        allowNoPayment: true,
      ),
    );
    if (payment == null || !mounted) return;
    try {
      if (payment['without_payment'] == true) {
        await context.read<AppointmentRepository>().updateStatus(
              appointment: appointment,
              status: 'completed',
            );
      } else {
        await context.read<AppointmentRepository>().addPayment(
              appointmentId: appointment.id,
              amount: payment['amount'] as double,
              method: payment['method'] as String,
              complete: true,
            );
      }
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addPayment(AppointMent appointment) async {
    final paid = appointment.payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final suggested = (appointment.totalPrice - paid).clamp(0, double.infinity);
    final payment = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(
        amount: suggested > 0 ? suggested.toDouble() : 0,
      ),
    );
    if (payment == null || !mounted) return;
    try {
      await context.read<AppointmentRepository>().addPayment(
            appointmentId: appointment.id,
            amount: payment['amount'] as double,
            method: payment['method'] as String,
          );
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
              IconButton(
                tooltip: 'Ανανέωση',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<AppointmentProvider>(
              builder: (context, provider, child) {
                final status = provider.appointmentState.appointmentStatus;
                if (status == AppointmentStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (status == AppointmentStatus.error) {
                  return Center(
                    child: TextButton(
                      onPressed: _refresh,
                      child: const Text('Κάτι πήγε στραβά — προσπάθησε ξανά'),
                    ),
                  );
                }
                final appointments = provider.appointmentsByDate;
                if (appointments.isEmpty || status == AppointmentStatus.empty) {
                  return const Center(child: Text('Καμία καταχώρηση'));
                }
                final collected = appointments.fold<double>(
                  0,
                  (sum, appointment) =>
                      sum +
                      (appointment.payments.isEmpty
                          ? (appointment.paid ?? 0).toDouble()
                          : appointment.payments.fold<double>(
                              0,
                              (paymentSum, payment) =>
                                  paymentSum + payment.amount,
                            )),
                );
                return ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Ημερήσιες εισπράξεις: ${collected.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    ...appointments.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                        onStatus: (value) => _changeStatus(appointment, value),
                        onPayment: () => _addPayment(appointment),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointMent appointment;
  final ValueChanged<String> onStatus;
  final VoidCallback onPayment;

  const _AppointmentCard({
    required this.appointment,
    required this.onStatus,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final paid = appointment.payments.isEmpty
        ? (appointment.paid ?? 0).toDouble()
        : appointment.payments.fold<double>(
            0,
            (sum, payment) => sum + payment.amount,
          );
    final services = appointment.serviceItems.isEmpty
        ? ''
        : appointment.serviceItems.map((item) => item.serviceName).join(', ');
    final employees = appointment.serviceItems
        .map((item) => item.employeeName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(', ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${appointment.name} ${appointment.surname}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: appointment.status),
                PopupMenuButton<String>(
                  tooltip: 'Κατάσταση',
                  onSelected: onStatus,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'confirmed', child: Text('Επιβεβαιώθηκε')),
                    PopupMenuItem(value: 'arrived', child: Text('Προσήλθε')),
                    PopupMenuItem(
                        value: 'in_progress', child: Text('Σε εξέλιξη')),
                    PopupMenuItem(
                        value: 'completed', child: Text('Ολοκλήρωση')),
                    PopupMenuItem(value: 'cancelled', child: Text('Ακύρωση')),
                    PopupMenuItem(
                        value: 'no_show', child: Text('Δεν προσήλθε')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text(
                  appointment.date == null
                      ? 'Χωρίς ημερομηνία'
                      : DateFormat('HH:mm').format(appointment.date!.toDate()),
                ),
                if (services.isNotEmpty) Text(services),
                if (employees.isNotEmpty) Text(employees),
                if (employees.isEmpty &&
                    (appointment.employee ?? '').isNotEmpty)
                  Text(appointment.employee!),
                if ((appointment.position ?? '').isNotEmpty)
                  Text(appointment.position!),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Σύνολο: ${appointment.totalPrice.toStringAsFixed(2)} €'),
                Text('Πληρωμένα: ${paid.toStringAsFixed(2)} €'),
                Text('Διάρκεια: ${appointment.totalDurationMinutes}′'),
                OutlinedButton.icon(
                  onPressed: onPayment,
                  icon: const Icon(Icons.payments),
                  label: const Text('Καταχώρηση πληρωμής'),
                ),
              ],
            ),
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(appointment.notes),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    const labels = {
      'scheduled': 'Προγραμματισμένο',
      'confirmed': 'Επιβεβαιωμένο',
      'arrived': 'Προσήλθε',
      'in_progress': 'Σε εξέλιξη',
      'completed': 'Ολοκληρωμένο',
      'cancelled': 'Ακυρωμένο',
      'no_show': 'Δεν προσήλθε',
    };
    return Chip(label: Text(labels[status] ?? status));
  }
}

class _PaymentDialog extends StatefulWidget {
  final double amount;
  final bool allowNoPayment;

  const _PaymentDialog({required this.amount, this.allowNoPayment = false});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount;
  String _method = 'cash';

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Πληρωμή ραντεβού'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ποσό €'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Τρόπος πληρωμής'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Μετρητά')),
                DropdownMenuItem(value: 'card', child: Text('Κάρτα')),
                DropdownMenuItem(
                    value: 'bank_transfer', child: Text('Τραπεζική μεταφορά')),
                DropdownMenuItem(value: 'other', child: Text('Άλλο')),
              ],
              onChanged: (value) => setState(() => _method = value ?? 'cash'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.allowNoPayment)
          TextButton(
            onPressed: () => Navigator.pop(context, {'without_payment': true}),
            child: const Text('Ολοκλήρωση χωρίς πληρωμή'),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
            if (amount == null || amount <= 0) return;
            Navigator.pop(context, {'amount': amount, 'method': _method});
          },
          child: const Text('Καταχώρηση'),
        ),
      ],
    );
  }
}
