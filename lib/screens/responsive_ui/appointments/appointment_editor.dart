import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/booking_models.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';

class AppointmentEditor extends StatefulWidget {
  const AppointmentEditor({super.key});

  @override
  State<AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<AppointmentEditor> {
  final TextEditingController _notesController = TextEditingController();
  TextEditingController? _clientSearchController;
  List<AppointMent> _clients = [];
  List<ServiceOffering> _services = [];
  List<StoreStation> _stations = [];
  final List<_ServiceLineDraft> _lines = [];
  AppointMent? _client;
  StoreStation? _station;
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  bool _loading = true;
  bool _saving = false;
  String? _error;

  double get _totalPrice => _lines.fold<double>(
        0,
        (sum, line) => sum + (double.tryParse(line.priceController.text) ?? 0),
      );

  int get _totalDuration => _lines.fold<int>(
        0,
        (sum, line) => sum + (int.tryParse(line.durationController.text) ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repository = context.read<AddAppointmentRepository>();
      final values = await Future.wait([
        repository.getClients(),
        repository.getServices(),
        repository.getStations(),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = values[0] as List<AppointMent>;
        _services = values[1] as List<ServiceOffering>;
        _stations = values[2] as List<StoreStation>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _start =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _addService() async {
    if (_services.isEmpty) {
      setState(() => _error = 'Δημιούργησε πρώτα υπηρεσίες από τις Ρυθμίσεις.');
      return;
    }
    final selected = await showDialog<ServiceOffering>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Προσθήκη υπηρεσίας'),
        children: _services
            .map(
              (service) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, service),
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text(
                    [service.category, service.subcategory]
                        .where((value) => value.isNotEmpty)
                        .join(' • '),
                  ),
                  trailing: Text(
                    '${service.price.toStringAsFixed(2)} € • ${service.durationMinutes}′',
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;
    try {
      final employees = await context
          .read<AddAppointmentRepository>()
          .getEmployees(serviceId: selected.id);
      if (!mounted) return;
      setState(() {
        _lines.add(_ServiceLineDraft(selected, employees));
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _newClient() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _NewClientDialog(),
    );
    if (result == null || !mounted) return;
    final repository = context.read<AddAppointmentRepository>();
    try {
      final duplicate = await repository.findDuplicateClient(result['phone']!);
      bool allowDuplicate = false;
      if (duplicate != null && mounted) {
        final useExisting = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Υπάρχει ήδη πελάτης με αυτό το τηλέφωνο'),
            content: Text('${duplicate.name} ${duplicate.surname}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Δημιουργία δεύτερης καρτέλας'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Άνοιγμα υπάρχουσας'),
              ),
            ],
          ),
        );
        if (useExisting == true) {
          setState(() {
            _client = duplicate;
            _clientSearchController?.text = _clientLabel(duplicate);
          });
          return;
        }
        allowDuplicate = true;
      }
      final client = await repository.createClient(
        name: result['name']!,
        surname: result['surname']!,
        phone: result['phone']!,
        email: result['email']!,
        source: result['source']!,
        allowDuplicate: allowDuplicate,
      );
      if (!mounted) return;
      setState(() {
        _clients = [..._clients, client];
        _client = client;
        _clientSearchController?.text = _clientLabel(client);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_client == null) {
      setState(() => _error = 'Επίλεξε πελάτη.');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'Πρόσθεσε τουλάχιστον μία υπηρεσία.');
      return;
    }
    if (_lines.any((line) => line.employee == null)) {
      setState(() => _error = 'Επίλεξε εργαζόμενο για κάθε υπηρεσία.');
      return;
    }
    final servicePayload = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final price =
          double.tryParse(line.priceController.text.replaceAll(',', '.'));
      final duration = int.tryParse(line.durationController.text);
      if (price == null || price < 0 || duration == null || duration < 1) {
        setState(() => _error = 'Έλεγξε τις τιμές και τις διάρκειες.');
        return;
      }
      servicePayload.add({
        'service_id': line.service.id,
        'employee_id': line.employee!.id,
        'price': price,
        'duration_minutes': duration,
      });
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AddAppointmentRepository>().createBooking(
            clientId: _client!.id,
            start: _start,
            services: servicePayload,
            stationId: _station?.id,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      for (final line in _lines) {
        line.dispose();
      }
      setState(() {
        _lines.clear();
        _client = null;
        _clientSearchController?.clear();
        _station = null;
        _notesController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Το ραντεβού αποθηκεύτηκε.')),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _clients.isEmpty && _services.isEmpty) {
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

    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 20),
      children: [
        Text('Νέο ραντεβού', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Autocomplete<AppointMent>(
                displayStringForOption: _clientLabel,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return _clients.take(20);
                  return _clients.where((client) {
                    final searchable =
                        '${client.name} ${client.surname} ${client.phone}'
                            .toLowerCase();
                    return searchable.contains(query);
                  }).take(20);
                },
                onSelected: (value) => setState(() => _client = value),
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  _clientSearchController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Αναζήτηση πελάτη με όνομα ή τηλέφωνο',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) {
                      if (_client != null &&
                          controller.text != _clientLabel(_client!)) {
                        setState(() => _client = null);
                      }
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          maxWidth: 420,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final client = options.elementAt(index);
                            return ListTile(
                              title: Text('${client.name} ${client.surname}'),
                              subtitle: Text(client.phone),
                              onTap: () => onSelected(client),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _newClient,
              icon: const Icon(Icons.person_add),
              label: const Text('Νέα πελάτισσα / πελάτης'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.event),
              label: Text(DateFormat('dd/MM/yyyy HH:mm').format(_start)),
            ),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<StoreStation?>(
                initialValue: _station,
                decoration: const InputDecoration(
                  labelText: 'Σταθμός / Χώρος',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<StoreStation?>(
                    value: null,
                    child: Text('Χωρίς συγκεκριμένο χώρο'),
                  ),
                  ..._stations.map(
                    (station) => DropdownMenuItem<StoreStation?>(
                      value: station,
                      child: Text(station.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _station = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Υπηρεσίες', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Προσθήκη υπηρεσίας'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_lines.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Δεν έχουν προστεθεί υπηρεσίες.'),
            ),
          ),
        ..._lines.asMap().entries.map(
              (entry) => _ServiceLineCard(
                index: entry.key,
                line: entry.value,
                onChanged: () => setState(() {}),
                onRemove: () {
                  entry.value.dispose();
                  setState(() => _lines.removeAt(entry.key));
                },
              ),
            ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 30,
              runSpacing: 8,
              children: [
                Text('Συνολική διάρκεια: $_totalDuration λεπτά'),
                Text('Συνολικό ποσό: ${_totalPrice.toStringAsFixed(2)} €'),
                Text(
                  'Λήξη: ${DateFormat('HH:mm').format(_start.add(Duration(minutes: _totalDuration)))}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Σημειώσεις',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Αποθήκευση...' : 'Αποθήκευση ραντεβού'),
          ),
        ),
      ],
    );
  }

  String _clientLabel(AppointMent client) =>
      '${client.name} ${client.surname} • ${client.phone}';
}

class _ServiceLineDraft {
  final ServiceOffering service;
  final List<Employee> employees;
  final TextEditingController priceController;
  final TextEditingController durationController;
  Employee? employee;

  _ServiceLineDraft(this.service, this.employees)
      : priceController = TextEditingController(
          text: service.price.toStringAsFixed(2),
        ),
        durationController = TextEditingController(
          text: service.durationMinutes.toString(),
        );

  void dispose() {
    priceController.dispose();
    durationController.dispose();
  }
}

class _ServiceLineCard extends StatelessWidget {
  final int index;
  final _ServiceLineDraft line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ServiceLineCard({
    required this.index,
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${line.service.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete)),
              ],
            ),
            if (line.service.category.isNotEmpty)
              Text(
                [line.service.category, line.service.subcategory]
                    .where((value) => value.isNotEmpty)
                    .join(' • '),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<Employee>(
                    initialValue: line.employee,
                    decoration: const InputDecoration(
                      labelText: 'Εργαζόμενος',
                      border: OutlineInputBorder(),
                    ),
                    items: line.employees
                        .map(
                          (employee) => DropdownMenuItem(
                            value: employee,
                            child: Text('${employee.name} ${employee.surname}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      line.employee = value;
                      onChanged();
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: line.priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Τιμή €',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: TextField(
                    controller: line.durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Διάρκεια (λεπτά)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewClientDialog extends StatefulWidget {
  const _NewClientDialog();

  @override
  State<_NewClientDialog> createState() => _NewClientDialogState();
}

class _NewClientDialogState extends State<_NewClientDialog> {
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _source = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _phone.dispose();
    _email.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Νέα πελάτισσα / πελάτης'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Όνομα'),
              ),
              TextField(
                controller: _surname,
                decoration: const InputDecoration(labelText: 'Επώνυμο'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Κινητό'),
              ),
              TextField(
                controller: _email,
                decoration:
                    const InputDecoration(labelText: 'Email (προαιρετικό)'),
              ),
              TextField(
                controller: _source,
                decoration: const InputDecoration(
                  labelText: 'Πηγή πελάτη (Instagram, Google, σύσταση...)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Άκυρο'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty ||
                _surname.text.trim().isEmpty ||
                _phone.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'surname': _surname.text.trim(),
              'phone': _phone.text.trim(),
              'email': _email.text.trim(),
              'source': _source.text.trim(),
            });
          },
          child: const Text('Αποθήκευση'),
        ),
      ],
    );
  }
}
