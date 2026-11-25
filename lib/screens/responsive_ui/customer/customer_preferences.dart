import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scheldule/models/customer_field.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/customer_field_repository.dart';

class CustomerPreferences extends StatefulWidget {
  const CustomerPreferences({
    super.key,
    required this.customerId,
    required this.apiClient,
  });
  final String customerId;
  final ApiClient apiClient;

  @override
  State<CustomerPreferences> createState() => _CustomerPreferencesState();
}

class _CustomerPreferencesState extends State<CustomerPreferences> {
  final _form = GlobalKey<FormState>();
  List<CustomerField> _fields = [];
  Map<String, dynamic> _values = {};
  final Map<String, dynamic> _draft = {};
  List<Map<String, dynamic>> _employees = [], _services = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _loading = true, _saving = false;
  String? _error;
  int _request = 0, _epoch = 0;
  CustomerFieldRepository get _repository =>
      CustomerFieldRepository(apiClient: widget.apiClient);

  @override
  void initState() {
    super.initState();
    _subscribe();
    _load();
  }

  void _subscribe() {
    _subscriptions.add(
      widget.apiClient.watch('clients').listen((_) => _load()),
    );
    _subscriptions.add(
      widget.apiClient.watch('employees').listen((_) => _load()),
    );
    _subscriptions.add(
      widget.apiClient.watch('services').listen((_) => _load()),
    );
    _subscriptions.add(
      widget.apiClient.sessionChanges.listen((_) {
        _reset();
        _load();
      }),
    );
  }

  void _reset() {
    setState(() {
      _fields = [];
      _values = {};
      _employees = [];
      _services = [];
      _draft.clear();
      _loading = true;
      _saving = false;
      _error = null;
      _epoch++;
      _request++;
    });
  }

  @override
  void didUpdateWidget(CustomerPreferences oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiClient != widget.apiClient) {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      _subscribe();
    }
    if (oldWidget.customerId != widget.customerId ||
        oldWidget.apiClient != widget.apiClient) {
      _reset();
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    final revision = widget.apiClient.sessionRevision;
    try {
      final fields = (await _repository.getDefinitions())
          .where((field) => field.isPreference && field.active)
          .toList();
      if (!mounted ||
          request != _request ||
          revision != widget.apiClient.sessionRevision) {
        return;
      }
      if (fields.isEmpty) {
        setState(() {
          _fields = [];
          _loading = false;
          _error = null;
        });
        return;
      }
      final data = await Future.wait<dynamic>([
        _repository.getValues(widget.customerId),
        _repository.getReferences('/employee'),
        _repository.getReferences('/services'),
      ]);
      if (!mounted ||
          request != _request ||
          revision != widget.apiClient.sessionRevision) {
        return;
      }
      setState(() {
        _fields = fields;
        _values = data[0] as Map<String, dynamic>;
        _employees = data[1] as List<Map<String, dynamic>>;
        _services = data[2] as List<Map<String, dynamic>>;
        _draft.removeWhere(
          (key, _) => !fields.any((field) => field.key == key),
        );
        _loading = false;
        _error = null;
        _epoch++;
      });
    } catch (_) {
      if (mounted &&
          request == _request &&
          revision == widget.apiClient.sessionRevision) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν οι προτιμήσεις. Δοκίμασε ξανά.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _draft.isEmpty) return;
    final revision = widget.apiClient.sessionRevision;
    final clientId = widget.customerId;
    final submitted = Map<String, dynamic>.from(_draft);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.saveValues(clientId, submitted);
      if (!mounted ||
          revision != widget.apiClient.sessionRevision ||
          clientId != widget.customerId) {
        return;
      }
      setState(() => _draft.clear());
      await _load();
      if (mounted && revision == widget.apiClient.sessionRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Οι προτιμήσεις αποθηκεύτηκαν.')),
        );
      }
    } catch (error) {
      if (mounted &&
          revision == widget.apiClient.sessionRevision &&
          clientId == widget.customerId) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Δεν αποθηκεύτηκαν οι προτιμήσεις.',
        );
      }
    } finally {
      if (mounted &&
          revision == widget.apiClient.sessionRevision &&
          clientId == widget.customerId) {
        setState(() => _saving = false);
      }
    }
  }

  dynamic _value(CustomerField field) => _draft.containsKey(field.key)
      ? _draft[field.key]
      : (_values.containsKey(field.id)
            ? _values[field.id]
            : field.defaultValue);

  List<Map<String, dynamic>> _options(CustomerField field) {
    final reference = field.settings['reference'];
    if (reference == 'employee') {
      return [
        ...field.options,
        ..._employees.map(
          (employee) => {
            'value': employee['uuid'].toString(),
            'label':
                '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                    .trim(),
          },
        ),
      ];
    }
    if (reference == 'services') {
      return _services
          .map(
            (service) => {
              'value': service['id'].toString(),
              'label': service['name'].toString(),
            },
          )
          .toList();
    }
    return field.options;
  }

  Widget _field(CustomerField field) {
    final value = _value(field);
    if (field.type == 'select') {
      final options = _options(field);
      final selected = value?.toString() ?? 'not_specified';
      if (!options.any((option) => option['value'] == selected)) {
        options.add({
          'value': selected,
          'label': 'Προηγούμενη επιλογή (μη διαθέσιμη)',
        });
      }
      return DropdownButtonFormField<String>(
        key: ValueKey('${field.id}-$_epoch'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option['value'].toString(),
                child: Text(
                  option['label'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _saving
            ? null
            : (value) => setState(() => _draft[field.key] = value),
      );
    }
    if (field.type == 'multiselect') {
      final selected = List<String>.from(value as List? ?? const []);
      final options = _options(field);
      final unavailable = selected
          .where((id) => !options.any((option) => option['value'] == id))
          .toList();
      return InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (options.isEmpty && selected.isEmpty)
              const Text('Δεν υπάρχουν διαθέσιμες επιλογές'),
            ...options.map((option) {
              final id = option['value'].toString();
              return FilterChip(
                label: Text(option['label'].toString()),
                selected: selected.contains(id),
                onSelected: _saving
                    ? null
                    : (enabled) {
                        final next = [...selected];
                        enabled ? next.add(id) : next.remove(id);
                        setState(() => _draft[field.key] = next);
                      },
              );
            }),
            ...unavailable.map(
              (id) => InputChip(
                label: const Text('Μη διαθέσιμη υπηρεσία'),
                onDeleted: _saving
                    ? null
                    : () => setState(
                        () => _draft[field.key] = selected
                            .where((item) => item != id)
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      );
    }
    return TextFormField(
      key: ValueKey('${field.id}-$_epoch'),
      initialValue: (value ?? '').toString(),
      enabled: !_saving,
      minLines: 1,
      maxLines: field.settings['positive_integer'] == true ? 1 : 3,
      maxLength: field.settings['positive_integer'] == true ? 4 : 2000,
      keyboardType: field.settings['positive_integer'] == true
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (value) =>
          field.settings['positive_integer'] == true &&
              (value ?? '').isNotEmpty &&
              !RegExp(r'^[1-9]\d{0,3}$').hasMatch(value!)
          ? 'Βάλε έναν θετικό αριθμό ημερών'
          : null,
      onChanged: (value) => setState(() => _draft[field.key] = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _fields.isEmpty && _error == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.tune, color: theme.colorScheme.primary),
        title: const Text('Προτιμήσεις πελάτη'),
        subtitle: const Text(
          'Προαιρετικά στοιχεία για πιο προσωπική εξυπηρέτηση',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_fields.isNotEmpty)
            Form(
              key: _form,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 620
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Οι προτιμήσεις δεν δεσμεύουν εργαζόμενο ή ώρα και δεν προσθέτουν χρεώσεις σε ραντεβού.',
                      ),
                      const SizedBox(height: 20),
                      for (final group in [
                        'shared',
                        ..._fields
                            .map((field) => field.group)
                            .where((group) => group != 'shared')
                            .toSet(),
                      ]) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            group == 'shared'
                                ? 'Επικοινωνία & επισκέψεις'
                                : 'Προτιμήσεις υπηρεσιών',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Wrap(
                          spacing: 16,
                          runSpacing: 20,
                          children: _fields
                              .where((field) => field.group == group)
                              .map(
                                (field) => SizedBox(
                                  width: width,
                                  child: _field(field),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _saving || _draft.isEmpty ? null : _save,
                          icon: const Icon(Icons.check),
                          label: Text(
                            _saving ? 'Αποθήκευση…' : 'Αποθήκευση προτιμήσεων',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            TextButton(onPressed: _load, child: const Text('Δοκίμασε ξανά')),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
