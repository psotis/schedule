import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:scheldule/models/employee.dart';

class _Shift {
  _Shift([Map<String, dynamic>? data])
    : start = TextEditingController(
        text: (data?['start_time'] ?? '09:00').toString().substring(0, 5),
      ),
      end = TextEditingController(
        text: (data?['end_time'] ?? '17:00').toString().substring(0, 5),
      );
  final TextEditingController start, end;
  Map<String, dynamic> get json => {
    'start_time': start.text.trim(),
    'end_time': end.text.trim(),
  };
  void dispose() {
    start.dispose();
    end.dispose();
  }
}

class _DayOverride {
  _DayOverride(this.date, List<dynamic> data, [String text = ''])
    : shifts = data
          .map((item) => _Shift(Map<String, dynamic>.from(item as Map)))
          .toList(),
      note = TextEditingController(text: text);
  final String date;
  final List<_Shift> shifts;
  final TextEditingController note;
  void dispose() {
    note.dispose();
    for (final shift in shifts) {
      shift.dispose();
    }
  }
}

class EmployeeScheduleDialog extends StatefulWidget {
  const EmployeeScheduleDialog({super.key, required this.employee});
  final Employee employee;
  @override
  State<EmployeeScheduleDialog> createState() => _EmployeeScheduleDialogState();
}

class _EmployeeScheduleDialogState extends State<EmployeeScheduleDialog> {
  static const _names = [
    'Κυριακή',
    'Δευτέρα',
    'Τρίτη',
    'Τετάρτη',
    'Πέμπτη',
    'Παρασκευή',
    'Σάββατο',
  ];
  final _form = GlobalKey<FormState>();
  late final Map<int, List<_Shift>> _weekly;
  late final List<_DayOverride> _overrides;
  late bool _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enabled =
        widget.employee.weeklyScheduleEnabled ||
        widget.employee.availability.isNotEmpty;
    _weekly = {
      for (var day = 0; day < 7; day++)
        day: widget.employee.availability
            .where((item) => item['weekday'] == day)
            .map(_Shift.new)
            .toList(),
    };
    _overrides = widget.employee.scheduleExceptions
        .map(
          (item) => _DayOverride(
            item['date'].toString(),
            (item['intervals'] ?? []) as List,
            (item['note'] ?? '').toString(),
          ),
        )
        .toList();
    _overrides.sort((a, b) => a.date.compareTo(b.date));
  }

  String? _time(String? value) =>
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch((value ?? '').trim())
      ? null
      : 'Ώρα σε μορφή 09:00';

  Widget _shifts(List<_Shift> shifts) => Column(
    children: [
      for (final shift in shifts)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: shift.start,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Από (HH:mm)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: _time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: shift.end,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Έως (HH:mm)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: _time,
                ),
              ),
              IconButton(
                tooltip: 'Αφαίρεση βάρδιας',
                onPressed: () => setState(() {
                  shifts.remove(shift);
                  shift.dispose();
                }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: shifts.length >= 8
              ? null
              : () => setState(() => shifts.add(_Shift())),
          icon: const Icon(Icons.add),
          label: Text(
            shifts.isEmpty
                ? 'Προσθήκη βάρδιας'
                : 'Προσθήκη δεύτερης / άλλης βάρδιας',
          ),
        ),
      ),
    ],
  );

  Future<void> _addDates(bool week) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null || !mounted) return;
    final start = week ? date.subtract(Duration(days: date.weekday - 1)) : date;
    setState(() {
      for (var i = 0; i < (week ? 7 : 1); i++) {
        final day = start.add(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(day);
        if (!_overrides.any((item) => item.date == key)) {
          _overrides.add(
            _DayOverride(
              key,
              _weekly[day.weekday % 7]!.map((shift) => shift.json).toList(),
            ),
          );
        }
      }
      _overrides.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  bool _validShifts(List<_Shift> shifts) {
    final sorted = shifts.map((shift) => shift.json).toList()
      ..sort(
        (a, b) =>
            (a['start_time'] as String).compareTo(b['start_time'] as String),
      );
    for (var i = 0; i < sorted.length; i++) {
      if ((sorted[i]['end_time'] as String).compareTo(
            sorted[i]['start_time'] as String,
          ) <=
          0) {
        return false;
      }
      if (i > 0 &&
          (sorted[i]['start_time'] as String).compareTo(
                sorted[i - 1]['end_time'] as String,
              ) <
              0) {
        return false;
      }
    }
    return true;
  }

  void _save() {
    if (!_form.currentState!.validate()) {
      setState(() => _error = 'Έλεγξε τις ώρες. Χρησιμοποίησε μορφή 09:00.');
      return;
    }
    if ((_enabled && _weekly.values.any((shifts) => !_validShifts(shifts))) ||
        _overrides.any((day) => !_validShifts(day.shifts))) {
      setState(
        () => _error = 'Η λήξη πρέπει να είναι μετά την έναρξη και οι βάρδιες να μην επικαλύπτονται.',
      );
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'weekly_schedule_enabled': _enabled,
      'availability': [
        if (_enabled)
          for (final day in _weekly.entries)
            for (final shift in day.value) {'weekday': day.key, ...shift.json},
      ],
      'schedule_exceptions': [
        for (final day in _overrides)
          {
            'date': day.date,
            'intervals': day.shifts.map((shift) => shift.json).toList(),
            'note': day.note.text.trim(),
          },
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: SizedBox(
        width: 720,
        height: (MediaQuery.sizeOf(context).height - 40).clamp(280.0, 820.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ωράριο: ${widget.employee.name}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Κλείσιμο',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Κάθε ημέρα έχει δικές της ώρες. Οι εξαιρέσεις ημερομηνίας αντικαθιστούν το εβδομαδιαίο ωράριο για εκείνη την ημέρα. Οι άδειες και τα υπάρχοντα ραντεβού εξακολουθούν να ελέγχονται.',
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Εβδομαδιαίο ωράριο'),
                          subtitle: Text(
                            _enabled ? 'Ημέρα χωρίς βάρδια = ρεπό' : 'Χωρίς εβδομαδιαίο περιορισμό. Ισχύουν οι εξαιρέσεις και οι άδειες.',
                          ),
                          value: _enabled,
                          onChanged: (value) =>
                              setState(() => _enabled = value),
                        ),
                        if (_enabled)
                          for (final day in [1, 2, 3, 4, 5, 6, 0])
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _names[day],
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_weekly[day]!.isEmpty)
                                      const Text('Ρεπό'),
                                    _shifts(_weekly[day]!),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: 24),
                        Text(
                          'Κυλιόμενο πρόγραμμα / ημερομηνίες',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Πρόσθεσε ημέρα ή ολόκληρη εβδομάδα και προσάρμοσε τις βάρδιες. Μια ημερομηνία χωρίς βάρδιες είναι ρεπό. Η αφαίρεσή της επαναφέρει το εβδομαδιαίο ωράριο.',
                        ),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton.icon(
                              onPressed: () => _addDates(false),
                              icon: const Icon(Icons.add),
                              label: const Text('Ημέρα'),
                            ),
                            TextButton.icon(
                              onPressed: () => _addDates(true),
                              icon: const Icon(Icons.date_range),
                              label: const Text('Εβδομάδα'),
                            ),
                          ],
                        ),
                        for (final day in _overrides)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(DateTime.parse(day.date)),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Αφαίρεση εξαίρεσης',
                                        onPressed: () => setState(() {
                                          _overrides.remove(day);
                                          day.dispose();
                                        }),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  if (day.shifts.isEmpty) const Text('Ρεπό'),
                                  _shifts(day.shifts),
                                  TextFormField(
                                    controller: day.note,
                                    maxLength: 255,
                                    decoration: const InputDecoration(
                                      labelText: 'Σημείωση (προαιρετικό)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Άκυρο'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Αποθήκευση'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final shifts in _weekly.values) {
      for (final shift in shifts) {
        shift.dispose();
      }
    }
    for (final day in _overrides) {
      day.dispose();
    }
    super.dispose();
  }
}
