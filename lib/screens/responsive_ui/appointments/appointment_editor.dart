import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/booking_models.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';

Future<bool?> showAppointmentEditor(
        BuildContext context, AppointMent? appointment,
        {DateTime? initialStart}) =>
    showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(context).height * .9,
          child: Column(children: [
            Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close))),
            Expanded(
                child: AppointmentEditor(
                    appointment: appointment,
                    initialStart: initialStart,
                    onSaved: () => Navigator.pop(context, true))),
          ]),
        ),
      ),
    );

class AppointmentEditor extends StatefulWidget {
  final AppointMent? appointment;
  final VoidCallback? onSaved;
  final DateTime? initialStart;
  const AppointmentEditor(
      {super.key, this.appointment, this.onSaved, this.initialStart});

  @override
  State<AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<AppointmentEditor> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientSurnameController =
      TextEditingController();
  TextEditingController? _clientSearchController;
  List<AppointMent> _clients = [];
  List<ServiceOffering> _services = [];
  List<StoreStation> _stations = [];
  final List<_ServiceLineDraft> _lines = [];
  AppointMent? _client;
  StoreStation? _station;
  Employee? _employee;
  String? _pendingEmployeeId;
  List<Employee> _appointmentEmployees = [];
  bool _employeeRequiresReview = false;
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Timer? _availabilityDebounce;
  int _availabilityRequest = 0;
  final List<StreamSubscription<void>> _availabilityChanges = [];
  bool _validating = false;

  double get _totalPrice => _lines.fold<double>(
        0,
        (sum, line) => sum + (double.tryParse(line.priceController.text) ?? 0),
      );

  int get _totalDuration => _lines.fold<int>(
        _lines.isEmpty ? widget.appointment?.effectiveDurationMinutes ?? 60 : 0,
        (sum, line) => sum + (int.tryParse(line.durationController.text) ?? 0),
      );

  @override
  void initState() {
    super.initState();
    if (widget.initialStart != null) _start = widget.initialStart!;
    if (widget.appointment?.date != null) {
      _start = widget.appointment!.date!.toDate();
    }
    _load();
    for (final resource in ['appointments', 'availability', 'employees']) {
      _availabilityChanges.add(context
          .read<ApiClient>()
          .watch(resource)
          .listen((_) => _scheduleAvailabilityRefresh()));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _availabilityDebounce?.cancel();
    for (final subscription in _availabilityChanges) {
      subscription.cancel();
    }
    _clientNameController.dispose();
    _clientSurnameController.dispose();
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
        _error = null;
      });
      final appointment = widget.appointment;
      if (appointment != null) {
        _client = _clients
            .where((client) => client.id == appointment.clientId)
            .firstOrNull;
        _clientNameController.text = appointment.name;
        _clientSurnameController.text = appointment.surname;
        _station = _stations
            .where((station) => station.id == appointment.stationId)
            .firstOrNull;
        _notesController.text = appointment.notes;
        if (appointment.employeeId.isNotEmpty &&
            appointment.serviceItems.every(
              (line) => line.employeeId == appointment.employeeId,
            )) {
          _pendingEmployeeId = appointment.employeeId;
        }
        for (final item in appointment.serviceItems) {
          final service = ServiceOffering(
              id: item.serviceId,
              name: item.serviceName,
              description: '',
              category: item.category,
              subcategory: item.subcategory,
              price: item.price,
              durationMinutes: item.durationMinutes,
              isActive: true);
          final line = _ServiceLineDraft(service, [], id: item.id);
          line.selectedEmployeeId = item.employeeId;
          _lines.add(line);
        }
      }
      await _refreshAvailableEmployees();
      if (mounted) setState(() => _loading = false);
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
      firstDate: DateTime(2000),
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
    await _refreshAvailableEmployees();
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
      final offset = _lines.fold<int>(
        0,
        (sum, line) =>
            sum +
            (int.tryParse(line.durationController.text) ??
                line.service.durationMinutes),
      );
      final serviceStart = _start.add(Duration(minutes: offset));
      final employees =
          await context.read<AddAppointmentRepository>().getEmployees(
                serviceId: selected.id,
                excludeAppointmentId: widget.appointment?.id,
                start: serviceStart,
                end: serviceStart.add(
                  Duration(minutes: selected.durationMinutes),
                ),
              );
      if (!mounted) return;
      setState(() {
        _lines.add(_ServiceLineDraft(selected, employees));
        _error = null;
      });
      await _refreshAvailableEmployees();
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
            _clientNameController.text = duplicate.name;
            _clientSurnameController.text = duplicate.surname;
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
        _clientNameController.text = client.name;
        _clientSurnameController.text = client.surname;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _save() async {
    if (_saving || _validating) return;
    final clientName = _clientNameController.text.trim();
    final clientSurname = _clientSurnameController.text.trim();
    if (clientName.isEmpty || clientSurname.isEmpty) {
      setState(() => _error = 'Συμπλήρωσε όνομα και επώνυμο πελάτη.');
      return;
    }
    _validating = true;
    final removedUnavailableSelection = await _refreshAvailableEmployees();
    _validating = false;
    if (removedUnavailableSelection ||
        _employeeRequiresReview ||
        _lines.any((line) => line.requiresReview) ||
        !mounted) {
      if (mounted) {
        setState(() {
          _error =
              'Ο επιλεγμένος εργαζόμενος δεν είναι διαθέσιμος αυτή την ώρα. Επίλεξε άλλον εργαζόμενο.';
        });
      }
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
        if (line.id != null) 'id': line.id,
        'service_id': line.service.id,
        'employee_id': line.employee?.id ?? _employee?.id,
        'price': price,
        'duration_minutes': duration,
      });
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var selectedClient = _client;
      if (selectedClient == null) {
        final matchingClients = _clients.where(
          (client) =>
              client.name.trim().toLowerCase() == clientName.toLowerCase() &&
              client.surname.trim().toLowerCase() ==
                  clientSurname.toLowerCase(),
        );
        if (matchingClients.length > 1) {
          setState(() {
            _error =
                'Υπάρχουν περισσότεροι πελάτες με αυτό το όνομα. Επίλεξε τον σωστό από την αναζήτηση.';
          });
          return;
        }
        selectedClient = matchingClients.isEmpty
            ? await context.read<AddAppointmentRepository>().createClient(
                  name: clientName,
                  surname: clientSurname,
                  phone: '',
                  email: '',
                )
            : matchingClients.first;
      }
      if (!mounted) return;
      await context.read<AddAppointmentRepository>().createBooking(
            appointmentId: widget.appointment?.id,
            employeeId: _employee?.id,
            fallbackDuration:
                widget.appointment?.effectiveDurationMinutes ?? 60,
            clientId: selectedClient.id,
            start: _start,
            services: servicePayload,
            stationId: _station?.id,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
        return;
      }
      for (final line in _lines) {
        line.dispose();
      }
      setState(() {
        _lines.clear();
        _client = null;
        _clientSearchController?.clear();
        _clientNameController.clear();
        _clientSurnameController.clear();
        _station = null;
        _employee = null;
        _pendingEmployeeId = null;
        _employeeRequiresReview = false;
        _notesController.clear();
      });
      _scheduleAvailabilityRefresh();
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
        Text(
            widget.appointment == null
                ? 'Νέο ραντεβού'
                : 'Επεξεργασία ραντεβού',
            style: Theme.of(context).textTheme.headlineSmall),
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
                    return client.matchesSearch(query);
                  }).take(20);
                },
                onSelected: (value) {
                  setState(() {
                    _client = value;
                    _clientNameController.text = value.name;
                    _clientSurnameController.text = value.surname;
                  });
                },
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Όνομα',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _clearSelectedClientIfNameChanged(),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _clientSurnameController,
                decoration: const InputDecoration(
                  labelText: 'Επώνυμο',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _clearSelectedClientIfNameChanged(),
              ),
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
                isExpanded: true,
                initialValue: _station,
                decoration: const InputDecoration(
                  labelText: 'Σταθμός / Χώρος',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<StoreStation?>(
                    value: null,
                    child: Text('Χωρίς συγκεκριμένο χώρο',
                        overflow: TextOverflow.ellipsis),
                  ),
                  ..._stations.map(
                    (station) => DropdownMenuItem<StoreStation?>(
                      value: station,
                      child:
                          Text(station.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _station = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<Employee?>(
          key: ValueKey(
              'appointment-employee-${_employee?.id}-${_appointmentEmployees.map((item) => item.id).join(',')}'),
          isExpanded: true,
          initialValue: _employee,
          decoration: InputDecoration(
            labelText: 'Εργαζόμενος (προαιρετικό)',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            helperText: 'Μπορείς να επιλέξεις εργαζόμενο και χωρίς υπηρεσία.',
            helperMaxLines: 2,
            errorText: _employeeRequiresReview
                ? 'Ο εργαζόμενος δεν είναι διαθέσιμος. Επίλεξε άλλον ή χωρίς εργαζόμενο.'
                : null,
            errorMaxLines: 3,
          ),
          items: [
            const DropdownMenuItem<Employee?>(
                value: null, child: Text('Χωρίς εργαζόμενο')),
            ..._appointmentEmployees
                .map((employee) => DropdownMenuItem<Employee?>(
                      value: employee,
                      child: Text('${employee.name} ${employee.surname}',
                          overflow: TextOverflow.ellipsis),
                    )),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() {
                    _employee = value;
                    _employeeRequiresReview = false;
                    if (value != null) {
                      for (final line in _lines) {
                        line.employee = null;
                        line.selectedEmployeeId = null;
                        line.requiresReview = false;
                      }
                    }
                  }),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Υπηρεσίες (προαιρετικά)',
                style: Theme.of(context).textTheme.titleLarge),
            FilledButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Προσθήκη υπηρεσίας'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_lines.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Χωρίς υπηρεσία το ραντεβού θα έχει διάρκεια $_totalDuration λεπτά.',
              ),
            ),
          ),
        ..._lines.asMap().entries.map(
              (entry) => _ServiceLineCard(
                index: entry.key,
                line: entry.value,
                defaultEmployee: _employee,
                onChanged: () {
                  setState(() {});
                  _scheduleAvailabilityRefresh();
                },
                onRemove: () {
                  entry.value.dispose();
                  setState(() => _lines.removeAt(entry.key));
                  _scheduleAvailabilityRefresh();
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

  String _clientLabel(AppointMent client) => [
        '${client.name} ${client.surname}',
        if (client.phone.trim().isNotEmpty) client.phone,
      ].join(' • ');

  Future<bool> _refreshAvailableEmployees() async {
    final request = ++_availabilityRequest;
    var offset = 0;
    var removedSelection = false;
    try {
      final candidates = await context
          .read<AddAppointmentRepository>()
          .getEmployees(
            start: _start,
            end: _start.add(
                Duration(minutes: _totalDuration > 0 ? _totalDuration : 60)),
            excludeAppointmentId: widget.appointment?.id,
          );
      if (!mounted || request != _availabilityRequest) return true;
      _appointmentEmployees = candidates
          .where((employee) => _lines.every((line) =>
              employee.serviceIds.contains(line.service.id) ||
              (line.id != null &&
                  (line.employee?.id ?? line.selectedEmployeeId) ==
                      employee.id)))
          .toList();
      final appointmentEmployeeId = _employee?.id ?? _pendingEmployeeId;
      _pendingEmployeeId = null;
      _employee = _appointmentEmployees
          .where((item) => item.id == appointmentEmployeeId)
          .firstOrNull;
      if (appointmentEmployeeId != null && _employee == null) {
        _employeeRequiresReview = true;
        removedSelection = true;
      }
      for (final line in _lines) {
        final duration = int.tryParse(line.durationController.text) ??
            line.service.durationMinutes;
        final lineStart = _start.add(Duration(minutes: offset));
        final employees =
            await context.read<AddAppointmentRepository>().getEmployees(
                  serviceId: line.service.id,
                  start: lineStart,
                  end: lineStart.add(Duration(minutes: duration)),
                  excludeAppointmentId: widget.appointment?.id,
                );
        if (!mounted ||
            request != _availabilityRequest ||
            !_lines.contains(line)) {
          return true;
        }
        final selectedId = line.employee?.id ?? line.selectedEmployeeId;
        line.employees = employees;
        line.employee = employees
            .where((employee) => employee.id == selectedId)
            .firstOrNull;
        line.selectedEmployeeId = null;
        if (selectedId != null &&
            !employees.any((employee) => employee.id == selectedId)) {
          line.employee = null;
          line.requiresReview = true;
          removedSelection = true;
        }
        offset += duration;
      }
      if (mounted) setState(() {});
      return removedSelection;
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return true;
    }
  }

  void _clearSelectedClientIfNameChanged() {
    final client = _client;
    if (client == null) return;
    if (_clientNameController.text.trim() != client.name ||
        _clientSurnameController.text.trim() != client.surname) {
      setState(() {
        _client = null;
        _clientSearchController?.clear();
      });
    }
  }

  void _scheduleAvailabilityRefresh() {
    _availabilityDebounce?.cancel();
    _availabilityDebounce =
        Timer(const Duration(milliseconds: 350), _refreshAvailableEmployees);
  }
}

class _ServiceLineDraft {
  final String? id;
  String? selectedEmployeeId;
  bool requiresReview = false;
  final ServiceOffering service;
  List<Employee> employees;
  final TextEditingController priceController;
  final TextEditingController durationController;
  Employee? employee;

  _ServiceLineDraft(this.service, this.employees, {this.id})
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
  final Employee? defaultEmployee;

  const _ServiceLineCard({
    required this.index,
    required this.line,
    required this.onChanged,
    required this.onRemove,
    this.defaultEmployee,
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
            if (line.requiresReview)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                    'Ο προηγούμενος εργαζόμενος δεν είναι διαθέσιμος. Επίλεξε άλλον ή «Χωρίς εργαζόμενο».',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<Employee?>(
                    isExpanded: true,
                    key: ValueKey(
                      '${line.service.id}-${line.employee?.id ?? 'none'}-'
                      '${line.employees.map((employee) => employee.id).join(',')}',
                    ),
                    initialValue: line.employee,
                    decoration: const InputDecoration(
                      labelText: 'Εργαζόμενος υπηρεσίας (προαιρετικό)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<Employee?>(
                        value: null,
                        child: Text(
                            defaultEmployee == null
                                ? 'Χωρίς εργαζόμενο'
                                : '${defaultEmployee!.name} ${defaultEmployee!.surname} (ραντεβού)',
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...line.employees.map(
                        (employee) => DropdownMenuItem<Employee?>(
                          value: employee,
                          child: Text('${employee.name} ${employee.surname}',
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      line.employee = value;
                      line.requiresReview = false;
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
            spacing: 14,
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
                decoration: const InputDecoration(
                  labelText: 'Κινητό (προαιρετικό)',
                ),
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
            if (_name.text.trim().isEmpty || _surname.text.trim().isEmpty) {
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
