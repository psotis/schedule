import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/booking_models.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';

class BusinessSettings extends StatefulWidget {
  const BusinessSettings({super.key});

  @override
  State<BusinessSettings> createState() => _BusinessSettingsState();
}

class _BusinessSettingsState extends State<BusinessSettings> {
  List<ServiceOffering> _services = [];
  List<StoreStation> _stations = [];
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _timeOff = [];
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic> _report = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = context.read<AddAppointmentRepository>();
      final values = await Future.wait([
        booking.getServices(),
        booking.getStations(),
        booking.getEmployees(),
        booking.getEmployeeTimeOff(),
        booking.getStoreMembers(),
        context.read<AppointmentRepository>().getReport(),
      ]);
      if (!mounted) return;
      setState(() {
        _services = values[0] as List<ServiceOffering>;
        _stations = values[1] as List<StoreStation>;
        _employees = values[2] as List<Employee>;
        _timeOff = values[3] as List<Map<String, dynamic>>;
        _members = values[4] as List<Map<String, dynamic>>;
        _report = values[5] as Map<String, dynamic>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editService([ServiceOffering? service]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ServiceDialog(service: service),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().saveService(
            id: service?.id,
            name: result['name'] as String,
            category: result['category'] as String,
            subcategory: result['subcategory'] as String,
            price: result['price'] as double,
            durationMinutes: result['duration'] as int,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editStation([StoreStation? station]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StationDialog(station: station),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().saveStation(
            id: station?.id,
            name: result['name'] as String,
            capacity: result['capacity'] as int,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editEmployeeServices(Employee employee) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _EmployeeServicesDialog(
        employee: employee,
        services: _services,
      ),
    );
    if (selected == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().setEmployeeServices(
            employeeId: employee.id,
            serviceIds: selected,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editAvailability(Employee employee) async {
    final availability = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => _AvailabilityDialog(employee: employee),
    );
    if (availability == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().setEmployeeAvailability(
            employeeId: employee.id,
            availability: availability,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addTimeOff() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TimeOffDialog(employees: _employees),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().addEmployeeTimeOff(
            employeeId: result['employee_id'] as String,
            startsAt: result['starts_at'] as DateTime,
            endsAt: result['ends_at'] as DateTime,
            reason: result['reason'] as String,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteTimeOff(String id) async {
    try {
      await context.read<AddAppointmentRepository>().deleteEmployeeTimeOff(id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addMember() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _MemberDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<AddAppointmentRepository>().addStoreMember(
            email: result['email']!,
            role: result['role']!,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _updateMember(
    Map<String, dynamic> member, {
    String? role,
    bool? isActive,
  }) async {
    try {
      await context.read<AddAppointmentRepository>().updateStoreMember(
            membershipId: (member['id'] ?? '').toString(),
            role: role ?? (member['role'] ?? 'staff').toString(),
            isActive: isActive ?? member['is_active'] != false,
          );
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final switchTheme = context.watch<ThemeProvider>().state?.themeStatus;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Ξανά')),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Υπηρεσίες'),
                    Tab(text: 'Χώροι'),
                    Tab(text: 'Ομάδα'),
                    Tab(text: 'Άδειες'),
                    Tab(text: 'Πρόσβαση'),
                    Tab(text: 'Αναφορές'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Αλλαγή θέματος',
                onPressed: context.read<ThemeProvider>().changeTheme,
                icon: Icon(
                  switchTheme == ThemeStatus.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
              ),
              IconButton(
                tooltip: 'Ανανέωση',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _servicesView(),
                _stationsView(),
                _employeesView(),
                _timeOffView(),
                _membersView(),
                _reportsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesView() {
    return _SettingsList(
      title: 'Κατάλογος υπηρεσιών',
      description:
          'Οι υπηρεσίες είναι κοινή λειτουργία για κάθε τύπο επιχείρησης.',
      addLabel: 'Νέα υπηρεσία',
      onAdd: _editService,
      children: _services
          .map(
            (service) => ListTile(
              leading: const Icon(Icons.design_services),
              title: Text(service.name),
              subtitle: Text(
                [
                  service.category,
                  service.subcategory,
                  '${service.durationMinutes} λεπτά',
                ].where((value) => value.isNotEmpty).join(' • '),
              ),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${service.price.toStringAsFixed(2)} €'),
                  IconButton(
                    tooltip: 'Επεξεργασία',
                    onPressed: () => _editService(service),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _stationsView() {
    return _SettingsList(
      title: 'Χώροι και σταθμοί εργασίας',
      description:
          'Η χωρητικότητα αποτρέπει περισσότερα ταυτόχρονα ραντεβού από όσα εξυπηρετεί ο χώρος.',
      addLabel: 'Νέος χώρος',
      onAdd: _editStation,
      children: _stations
          .map(
            (station) => ListTile(
              leading: const Icon(Icons.chair_alt),
              title: Text(station.name),
              subtitle: Text('Χωρητικότητα: ${station.capacity}'),
              trailing: IconButton(
                tooltip: 'Επεξεργασία',
                onPressed: () => _editStation(station),
                icon: const Icon(Icons.edit),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _employeesView() {
    return _SettingsList(
      title: 'Ικανότητες και ωράριο ομάδας',
      description:
          'Όρισε ποιες υπηρεσίες εκτελεί κάθε εργαζόμενος και πότε είναι διαθέσιμος.',
      children: _employees
          .map(
            (employee) => ListTile(
              leading: const Icon(Icons.badge),
              title: Text('${employee.name} ${employee.surname}'),
              subtitle: Text(
                employee.serviceIds.isEmpty
                    ? 'Όλες οι υπηρεσίες (δεν έχουν οριστεί περιορισμοί)'
                    : '${employee.serviceIds.length} υπηρεσίες • ${employee.availability.length} κανόνες ωραρίου',
              ),
              trailing: Wrap(
                children: [
                  TextButton(
                    onPressed: () => _editEmployeeServices(employee),
                    child: const Text('Υπηρεσίες'),
                  ),
                  TextButton(
                    onPressed: () => _editAvailability(employee),
                    child: const Text('Ωράριο'),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _timeOffView() {
    return _SettingsList(
      title: 'Άδειες και μη διαθεσιμότητα',
      description:
          'Τα διαστήματα αυτά μπλοκάρουν αυτόματα νέα ραντεβού για τον εργαζόμενο.',
      addLabel: 'Νέα άδεια',
      onAdd: _employees.isEmpty ? null : _addTimeOff,
      children: _timeOff.map((item) {
        final employee = _employees.where(
          (value) => value.id == (item['employee_uuid'] ?? '').toString(),
        );
        final name = employee.isEmpty
            ? 'Εργαζόμενος'
            : '${employee.first.name} ${employee.first.surname}';
        final start = DateTime.tryParse((item['starts_at'] ?? '').toString());
        final end = DateTime.tryParse((item['ends_at'] ?? '').toString());
        return ListTile(
          leading: const Icon(Icons.event_busy),
          title: Text(name),
          subtitle: Text(
            '${_formatDate(start)} – ${_formatDate(end)}'
            '${(item['reason'] ?? '').toString().isEmpty ? '' : ' • ${item['reason']}'}',
          ),
          trailing: IconButton(
            tooltip: 'Διαγραφή',
            onPressed: () => _deleteTimeOff((item['id'] ?? '').toString()),
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }

  Widget _reportsView() {
    final totals = Map<String, dynamic>.from(
      (_report['totals'] ?? const <String, dynamic>{}) as Map,
    );
    final services = ((_report['services'] ?? const []) as List)
        .map((item) => ReportMetric.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final employees = ((_report['employees'] ?? const []) as List)
        .map((item) => ReportMetric.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard('Ραντεβού', totals['appointments'] ?? 0),
            _MetricCard('Ολοκληρωμένα', totals['completed'] ?? 0),
            _MetricCard('Ακυρώσεις', totals['cancelled'] ?? 0),
            _MetricCard('Δεν προσήλθαν', totals['no_show'] ?? 0),
            _MetricCard('Αξία υπηρεσιών', totals['service_value'] ?? 0,
                money: true),
            _MetricCard('Εισπράξεις', totals['collected'] ?? 0, money: true),
            _MetricCard('Υπόλοιπο', totals['outstanding'] ?? 0, money: true),
          ],
        ),
        const SizedBox(height: 24),
        Text('Απόδοση υπηρεσιών',
            style: Theme.of(context).textTheme.titleLarge),
        ...services.map(
          (metric) => ListTile(
            title: Text(metric.name),
            subtitle: Text('${metric.count} ολοκληρώσεις'),
            trailing: Text('${metric.value.toStringAsFixed(2)} €'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Απόδοση εργαζομένων',
            style: Theme.of(context).textTheme.titleLarge),
        ...employees.map(
          (metric) => ListTile(
            title: Text(metric.name),
            subtitle: Text('${metric.count} υπηρεσίες'),
            trailing: Text('${metric.value.toStringAsFixed(2)} €'),
          ),
        ),
      ],
    );
  }

  Widget _membersView() {
    return _SettingsList(
      title: 'Πρόσβαση ομάδας',
      description:
          'Οι διαχειριστές βλέπουν οικονομικά και ρυθμίσεις. Το προσωπικό βλέπει το λειτουργικό πρόγραμμα και τους πελάτες.',
      addLabel: 'Προσθήκη χρήστη',
      onAdd: _addMember,
      children: _members.map((member) {
        final user = Map<String, dynamic>.from(
          (member['user'] ?? const <String, dynamic>{}) as Map,
        );
        final role = (member['role'] ?? 'staff').toString();
        final active = member['is_active'] != false;
        return ListTile(
          leading: Icon(active ? Icons.person : Icons.person_off),
          title: Text((user['email'] ?? '').toString()),
          subtitle: Text(active ? 'Ενεργός χρήστης' : 'Ανενεργός χρήστης'),
          trailing: role == 'owner'
              ? const Chip(label: Text('Ιδιοκτήτης'))
              : Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text('Διαχειριστής'),
                        ),
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Προσωπικό'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) _updateMember(member, role: value);
                      },
                    ),
                    Switch(
                      value: active,
                      onChanged: (value) =>
                          _updateMember(member, isActive: value),
                    ),
                  ],
                ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime? value) => value == null
      ? '-'
      : DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
}

class _SettingsList extends StatelessWidget {
  final String title;
  final String description;
  final String? addLabel;
  final VoidCallback? onAdd;
  final List<Widget> children;

  const _SettingsList({
    required this.title,
    required this.description,
    this.addLabel,
    this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            if (addLabel != null)
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Δεν υπάρχουν ακόμη καταχωρήσεις.'),
            ),
          )
        else
          Card(child: Column(children: children)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool money;

  const _MetricCard(this.label, this.value, {this.money = false});

  @override
  Widget build(BuildContext context) {
    final parsed = num.tryParse(value.toString()) ?? 0;
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(
                money ? '${parsed.toStringAsFixed(2)} €' : '$parsed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final ServiceOffering? service;

  const _ServiceDialog({this.service});

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _subcategory;
  late final TextEditingController _price;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _name = TextEditingController(text: service?.name ?? '');
    _category = TextEditingController(text: service?.category ?? '');
    _subcategory = TextEditingController(text: service?.subcategory ?? '');
    _price =
        TextEditingController(text: service?.price.toStringAsFixed(2) ?? '0');
    _duration = TextEditingController(
        text: service?.durationMinutes.toString() ?? '30');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _subcategory.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.service == null ? 'Νέα υπηρεσία' : 'Επεξεργασία υπηρεσίας'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Όνομα')),
              TextField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Κατηγορία')),
              TextField(
                  controller: _subcategory,
                  decoration: const InputDecoration(labelText: 'Υποκατηγορία')),
              TextField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Τιμή €')),
              TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Διάρκεια (λεπτά)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(_price.text.replaceAll(',', '.'));
            final duration = int.tryParse(_duration.text);
            if (_name.text.trim().isEmpty ||
                price == null ||
                price < 0 ||
                duration == null ||
                duration < 1) return;
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'category': _category.text.trim(),
              'subcategory': _subcategory.text.trim(),
              'price': price,
              'duration': duration,
            });
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    );
  }
}

class _StationDialog extends StatefulWidget {
  final StoreStation? station;

  const _StationDialog({this.station});

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  late final TextEditingController _name;
  late final TextEditingController _capacity;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.station?.name ?? '');
    _capacity =
        TextEditingController(text: widget.station?.capacity.toString() ?? '1');
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.station == null ? 'Νέος χώρος' : 'Επεξεργασία χώρου'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Όνομα χώρου / σταθμού')),
            TextField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Ταυτόχρονη χωρητικότητα')),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () {
            final capacity = int.tryParse(_capacity.text);
            if (_name.text.trim().isEmpty || capacity == null || capacity < 1)
              return;
            Navigator.pop(
                context, {'name': _name.text.trim(), 'capacity': capacity});
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    );
  }
}

class _EmployeeServicesDialog extends StatefulWidget {
  final Employee employee;
  final List<ServiceOffering> services;

  const _EmployeeServicesDialog(
      {required this.employee, required this.services});

  @override
  State<_EmployeeServicesDialog> createState() =>
      _EmployeeServicesDialogState();
}

class _EmployeeServicesDialogState extends State<_EmployeeServicesDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.employee.serviceIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Υπηρεσίες: ${widget.employee.name}'),
      content: SizedBox(
        width: 480,
        child: ListView(
          shrinkWrap: true,
          children: widget.services
              .map((service) => CheckboxListTile(
                    value: _selected.contains(service.id),
                    title: Text(service.name),
                    subtitle: Text([service.category, service.subcategory]
                        .where((value) => value.isNotEmpty)
                        .join(' • ')),
                    onChanged: (value) => setState(() => value == true
                        ? _selected.add(service.id)
                        : _selected.remove(service.id)),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('Αποθήκευση')),
      ],
    );
  }
}

class _AvailabilityDialog extends StatefulWidget {
  final Employee employee;

  const _AvailabilityDialog({required this.employee});

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  static const _days = [
    'Κυριακή',
    'Δευτέρα',
    'Τρίτη',
    'Τετάρτη',
    'Πέμπτη',
    'Παρασκευή',
    'Σάββατο'
  ];
  late final Set<int> _selectedDays;
  late final TextEditingController _start;
  late final TextEditingController _end;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.employee.availability
        .map((item) => num.tryParse(item['weekday'].toString())?.round())
        .whereType<int>()
        .toSet();
    if (_selectedDays.isEmpty) _selectedDays.addAll([1, 2, 3, 4, 5]);
    final first = widget.employee.availability.isEmpty
        ? null
        : widget.employee.availability.first;
    _start = TextEditingController(
        text: _shortTime(first?['start_time']) ?? '09:00');
    _end =
        TextEditingController(text: _shortTime(first?['end_time']) ?? '17:00');
  }

  String? _shortTime(dynamic value) {
    final text = value?.toString();
    return text != null && text.length >= 5 ? text.substring(0, 5) : null;
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ωράριο: ${widget.employee.name}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Το κοινό ωράριο εφαρμόζεται στις επιλεγμένες ημέρες.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(
                  _days.length,
                  (index) => FilterChip(
                        selected: _selectedDays.contains(index),
                        label: Text(_days[index]),
                        onSelected: (selected) => setState(() => selected
                            ? _selectedDays.add(index)
                            : _selectedDays.remove(index)),
                      )),
            ),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _start,
                        decoration:
                            const InputDecoration(labelText: 'Από (HH:mm)'))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _end,
                        decoration:
                            const InputDecoration(labelText: 'Έως (HH:mm)'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () {
            final validTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
            if (_selectedDays.isEmpty ||
                !validTime.hasMatch(_start.text) ||
                !validTime.hasMatch(_end.text) ||
                _end.text.compareTo(_start.text) <= 0) return;
            Navigator.pop(
                context,
                _selectedDays
                    .map((day) => {
                          'weekday': day,
                          'start_time': _start.text,
                          'end_time': _end.text,
                        })
                    .toList());
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    );
  }
}

class _TimeOffDialog extends StatefulWidget {
  final List<Employee> employees;

  const _TimeOffDialog({required this.employees});

  @override
  State<_TimeOffDialog> createState() => _TimeOffDialogState();
}

class _TimeOffDialogState extends State<_TimeOffDialog> {
  Employee? _employee;
  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return AlertDialog(
      title: const Text('Νέα άδεια / μη διαθεσιμότητα'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Employee>(
              initialValue: _employee,
              decoration: const InputDecoration(labelText: 'Εργαζόμενος'),
              items: widget.employees
                  .map((employee) => DropdownMenuItem(
                      value: employee,
                      child: Text('${employee.name} ${employee.surname}')))
                  .toList(),
              onChanged: (value) => setState(() => _employee = value),
            ),
            ListTile(
              title: const Text('Έναρξη'),
              subtitle: Text(format.format(_startsAt)),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final value = await _pick(_startsAt);
                if (value != null) setState(() => _startsAt = value);
              },
            ),
            ListTile(
              title: const Text('Λήξη'),
              subtitle: Text(format.format(_endsAt)),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final value = await _pick(_endsAt);
                if (value != null) setState(() => _endsAt = value);
              },
            ),
            TextField(
                controller: _reason,
                decoration:
                    const InputDecoration(labelText: 'Αιτία (προαιρετικό)')),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο')),
        FilledButton(
          onPressed: () {
            if (_employee == null || !_endsAt.isAfter(_startsAt)) return;
            Navigator.pop(context, {
              'employee_id': _employee!.id,
              'starts_at': _startsAt,
              'ends_at': _endsAt,
              'reason': _reason.text.trim(),
            });
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    );
  }
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog();

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  final TextEditingController _email = TextEditingController();
  String _role = 'staff';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Προσθήκη χρήστη στο κατάστημα'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ο χρήστης πρέπει πρώτα να έχει δημιουργήσει λογαριασμό με αυτό το email.',
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Ρόλος'),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Προσωπικό')),
                DropdownMenuItem(
                  value: 'manager',
                  child: Text('Διαχειριστής'),
                ),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'staff'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Άκυρο'),
        ),
        FilledButton(
          onPressed: () {
            final email = _email.text.trim();
            if (!email.contains('@')) return;
            Navigator.pop(context, {'email': email, 'role': _role});
          },
          child: const Text('Προσθήκη'),
        ),
      ],
    );
  }
}
