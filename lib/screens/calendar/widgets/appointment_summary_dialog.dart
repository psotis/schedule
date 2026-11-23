import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class AppointmentSummaryDialog extends StatefulWidget {
  const AppointmentSummaryDialog({
    super.key,
    required this.customer,
    required this.start,
    required this.end,
    required this.employee,
    required this.station,
    required this.onDelete,
  });

  final String customer;
  final DateTime start;
  final DateTime end;
  final String employee;
  final String station;
  final Future<void> Function() onDelete;

  @override
  State<AppointmentSummaryDialog> createState() =>
      _AppointmentSummaryDialogState();
}

class _AppointmentSummaryDialogState extends State<AppointmentSummaryDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = 'Η διαγραφή απέτυχε. Δοκιμάστε ξανά.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget detail(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: const Text('Στοιχεία ραντεβού'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                detail(
                  Icons.person_outline_rounded,
                  'Πελάτης',
                  widget.customer,
                ),
                detail(
                  Icons.event_outlined,
                  'Ημερομηνία',
                  DateFormat('dd/MM/yyyy').format(widget.start),
                ),
                detail(
                  Icons.schedule_rounded,
                  'Ώρα',
                  '${DateFormat('HH:mm').format(widget.start)} – '
                      '${DateFormat(widget.start.day == widget.end.day && widget.start.month == widget.end.month && widget.start.year == widget.end.year ? 'HH:mm' : 'dd/MM/yyyy HH:mm').format(widget.end)}',
                ),
                detail(
                  Icons.badge_outlined,
                  'Εργαζόμενος',
                  widget.employee.trim().isEmpty
                      ? 'Χωρίς ανάθεση'
                      : widget.employee,
                ),
                detail(
                  Icons.place_outlined,
                  'Θέση / σταθμός',
                  widget.station.trim().isEmpty
                      ? 'Δεν έχει οριστεί'
                      : widget.station,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: colors.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: _deleting ? null : _delete,
            style: OutlinedButton.styleFrom(foregroundColor: colors.error),
            icon: _deleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(_deleting ? 'Διαγραφή…' : 'Διαγραφή'),
          ),
          FilledButton(
            onPressed: _deleting ? null : () => Navigator.pop(context, false),
            child: const Text('Κλείσιμο'),
          ),
        ],
      ),
    );
  }
}
