import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

enum CalendarLayout {
  day('day', 'Ημέρα', CalendarView.day),
  week('week', 'Εβδομάδα', CalendarView.week),
  workWeek('workWeek', 'Εργάσιμες ημέρες', CalendarView.workWeek),
  month('month', 'Μήνας & ατζέντα', CalendarView.month),
  agenda('agenda', 'Ατζέντα', CalendarView.schedule),
  resources('resources', 'Πρόγραμμα εργαζομένων', CalendarView.timelineDay),
  timelineDay('timelineDay', 'Χρονοδιάγραμμα ημέρας', CalendarView.timelineDay),
  timelineWeek(
      'timelineWeek', 'Χρονοδιάγραμμα εβδομάδας', CalendarView.timelineWeek),
  timelineWorkWeek('timelineWorkWeek', 'Χρονοδιάγραμμα εργασίμων',
      CalendarView.timelineWorkWeek),
  timelineMonth(
      'timelineMonth', 'Χρονοδιάγραμμα μήνα', CalendarView.timelineMonth),
  heatmap('heatmap', 'Χάρτης πληρότητας', CalendarView.month),
  dailySummary('dailySummary', 'Ημερήσια σύνοψη', CalendarView.month);

  final String key;
  final String label;
  final CalendarView view;
  const CalendarLayout(this.key, this.label, this.view);

  static CalendarLayout fromKey(String key, {bool compact = false}) =>
      values.firstWhere((layout) => layout.key == key,
          orElse: () => compact ? day : workWeek);

  String get description => switch (this) {
        resources =>
          'Ολόκληρη η επίσκεψη ανά συμμετέχοντα εργαζόμενο. Η ανάθεση αλλάζει από την επεξεργασία.',
        heatmap =>
          'Πιο έντονο χρώμα για ημέρες με περισσότερα ραντεβού. Επιλέξτε ημέρα για λεπτομέρειες.',
        dailySummary =>
          'Ραντεβού και συνολικός προγραμματισμένος χρόνος ανά ημέρα. Επιλέξτε ημέρα για την ατζέντα.',
        month =>
          'Επιλέξτε ημέρα για να δείτε τα ραντεβού της κάτω από τον μήνα.',
        agenda => 'Τα ραντεβού σας σε χρονολογική λίστα.',
        _ =>
          'Διπλό πάτημα σε κενή ώρα για νέο ραντεβού. Σύρετε ραντεβού για αλλαγή ώρας.',
      };
}

class CalendarLayoutPicker extends StatelessWidget {
  final CalendarLayout selected;
  final ValueChanged<CalendarLayout> onChanged;
  final String? error;
  const CalendarLayoutPicker(
      {super.key, required this.selected, required this.onChanged, this.error});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<CalendarLayout>(
            key: ValueKey(selected),
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Διάταξη ημερολογίου',
              prefixIcon: Icon(Icons.calendar_view_month_rounded),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: CalendarLayout.values
                .map((layout) => DropdownMenuItem(
                      value: layout,
                      child:
                          Text(layout.label, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: 8),
          Text(error ?? selected.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        error == null ? colors.onSurfaceVariant : colors.error,
                  )),
        ],
      ),
    );
  }
}
