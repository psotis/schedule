import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

enum CalendarAppointmentAction { edit, create }

class CalendarAppointmentActionDialog extends StatelessWidget {
  const CalendarAppointmentActionDialog({
    super.key,
    required this.customer,
    required this.start,
  });

  final String customer;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Τι θέλετε να κάνετε;'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                customer,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd/MM/yyyy • HH:mm').format(start),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, CalendarAppointmentAction.edit),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Επεξεργασία ραντεβού'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, CalendarAppointmentAction.create),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Νέο ραντεβού την ίδια ώρα'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Κλείσιμο'),
        ),
      ],
    );
  }
}
