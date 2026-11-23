import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';

/// Direct payment/status controls shared by the calendar detail panels.
class AppointmentPaymentPanel extends StatefulWidget {
  const AppointmentPaymentPanel({super.key, required this.appointment});

  final AppointMent appointment;

  @override
  State<AppointmentPaymentPanel> createState() =>
      _AppointmentPaymentPanelState();
}

class _AppointmentPaymentPanelState extends State<AppointmentPaymentPanel> {
  static const _statuses = {
    'scheduled': 'Προγραμματισμένο',
    'confirmed': 'Επιβεβαιωμένο',
    'arrived': 'Προσήλθε',
    'in_progress': 'Σε εξέλιξη',
    'completed': 'Ολοκληρωμένο',
    'cancelled': 'Ακυρωμένο',
    'no_show': 'Δεν προσήλθε',
  };
  static const _methods = {
    'cash': 'Μετρητά',
    'card': 'Κάρτα',
    'bank_transfer': 'Τραπεζική μεταφορά',
    'other': 'Άλλο',
  };

  late AppointMent _appointment;
  final _amount = TextEditingController();
  late final AppointmentRepository _repository;
  StreamSubscription<void>? _changes;
  String _method = 'cash';
  bool _busy = false;
  bool _needsRefresh = true;
  String? _error;
  String? _amountError;
  int _request = 0;
  int _statusRevision = 0;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _repository = context.read<AppointmentRepository>();
    _changes = _repository.changes.listen((_) => _refresh());
    _refresh();
  }

  @override
  void didUpdateWidget(covariant AppointmentPaymentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.id != widget.appointment.id) {
      _request++;
      _appointment = widget.appointment;
      _amount.clear();
      _error = null;
      _amountError = null;
      _needsRefresh = false;
      _refresh();
    }
  }

  Future<bool> _refresh() async {
    final request = ++_request;
    final revision = _repository.apiClient.sessionRevision;
    final id = _appointment.id;
    try {
      final appointments = await _repository.fetchAppointmentsByDate(
        date: _appointment.date?.toDate() ?? DateTime.now(),
      );
      if (!mounted ||
          request != _request ||
          revision != _repository.apiClient.sessionRevision ||
          id != _appointment.id) {
        return false;
      }
      final matches = appointments.where((item) => item.id == id);
      if (matches.isEmpty) throw StateError('Appointment unavailable');
      setState(() {
        _appointment = matches.first;
        _needsRefresh = false;
        _error = null;
      });
      return true;
    } catch (_) {
      if (mounted &&
          request == _request &&
          revision == _repository.apiClient.sessionRevision) {
        setState(() {
          _needsRefresh = true;
          _error = 'Δεν ήταν δυνατή η ανανέωση των στοιχείων. Πατήστε ανανέωση πριν συνεχίσετε.';
        });
      }
      return false;
    }
  }

  Future<void> _changeStatus(String? status) async {
    if (_busy ||
        _needsRefresh ||
        status == null ||
        status == _appointment.status) {
      return;
    }
    setState(() {
      _busy = true;
      _statusRevision++;
      _error = null;
    });
    try {
      final updated = await _repository.updateStatus(
        appointment: _appointment,
        status: status,
      );
      if (mounted) setState(() => _appointment = updated);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay({bool complete = false}) async {
    if (_busy || _needsRefresh) return;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _amountError = 'Συμπληρώστε ποσό μεγαλύτερο από 0.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _amountError = null;
    });
    try {
      await _repository.addPayment(
        appointmentId: _appointment.id,
        amount: amount,
        method: _method,
        complete: complete,
      );
      if (!mounted) return;
      // A committed payment must never be offered again if refreshing fails.
      _amount.clear();
      setState(() => _needsRefresh = true);
      final refreshed = await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshed ? 'Η πληρωμή καταχωρήθηκε.' : 'Η πληρωμή καταχωρήθηκε. Ανανεώστε τα στοιχεία για να δείτε το νέο σύνολο.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Η αποθήκευση απέτυχε. Δοκιμάστε ξανά.';

  @override
  void dispose() {
    _request++;
    _changes?.cancel();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paid = _appointment.paidAmount;
    final remaining = (_appointment.totalPrice - paid).clamp(
      0,
      double.infinity,
    );
    final enabled = !_busy && !_needsRefresh;
    final byMethod = <String, double>{};
    for (final payment in _appointment.payments) {
      byMethod.update(
        payment.method,
        (amount) => amount + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    Widget paymentMethod() => DropdownButtonFormField<String>(
      initialValue: _method,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Τρόπος νέας πληρωμής'),
      items: _methods.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: enabled
          ? (value) => setState(() => _method = value ?? 'cash')
          : null,
    );
    Widget amountField() => TextField(
      controller: _amount,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Νέα πληρωμή',
        suffixText: '€',
        hintText: remaining.toStringAsFixed(2),
        errorText: _amountError,
      ),
      onChanged: (_) {
        if (_amountError != null) setState(() => _amountError = null);
      },
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Κατάσταση & πληρωμές',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'appointment-status-${_appointment.id}-${_appointment.status}-$_statusRevision',
            ),
            initialValue: _appointment.status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Κατάσταση ραντεβού'),
            items:
                {
                      ..._statuses,
                      if (!_statuses.containsKey(_appointment.status))
                        _appointment.status: _appointment.status,
                    }.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged: enabled ? _changeStatus : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Η αλλαγή κατάστασης αποθηκεύεται αμέσως.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Σύνολο: ${_appointment.totalPrice.toStringAsFixed(2)} €'),
              Text('Πληρωμένα: ${paid.toStringAsFixed(2)} €'),
              Text('Υπόλοιπο: ${remaining.toStringAsFixed(2)} €'),
            ],
          ),
          if (byMethod.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: byMethod.entries
                  .map(
                    (entry) => Chip(
                      label: Text(
                        '${_methods[entry.key] ?? entry.key}: ${entry.value.toStringAsFixed(2)} €',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ] else if (paid > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Παλαιότερες πληρωμές χωρίς καταγεγραμμένο τρόπο.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 400
                ? Column(
                    children: [
                      amountField(),
                      const SizedBox(height: 16),
                      paymentMethod(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: amountField()),
                      const SizedBox(width: 12),
                      Expanded(child: paymentMethod()),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: enabled ? () => _pay() : null,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Καταχώρηση πληρωμής'),
              ),
              if (![
                'completed',
                'cancelled',
                'no_show',
              ].contains(_appointment.status))
                FilledButton.icon(
                  onPressed: enabled ? () => _pay(complete: true) : null,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Πληρωμή & ολοκλήρωση'),
                ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colors.error)),
            if (_needsRefresh)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ανανέωση στοιχείων'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
