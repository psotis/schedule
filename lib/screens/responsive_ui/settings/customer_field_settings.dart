import 'customer_merge_settings.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/customer_field.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/customer_field_repository.dart';

class CustomerFieldSettings extends StatefulWidget {
  const CustomerFieldSettings({super.key});

  @override
  State<CustomerFieldSettings> createState() => _CustomerFieldSettingsState();
}

class _CustomerFieldSettingsState extends State<CustomerFieldSettings> {
  List<CustomerField> _fields = [];
  bool _loading = true;
  String? _error, _saving;
  int _request = 0;
  late final ApiClient _api;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  CustomerFieldRepository get _repository =>
      CustomerFieldRepository(apiClient: _api);

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _subscriptions.add(_api.watch('store').listen((_) => _load()));
    _subscriptions.add(
      _api.sessionChanges.listen((_) {
        setState(() {
          _fields = [];
          _loading = true;
          _saving = null;
        });
        _load();
      }),
    );
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final revision = _api.sessionRevision;
    try {
      final fields = await _repository.getDefinitions();
      if (mounted && request == _request && revision == _api.sessionRevision) {
        setState(() {
          _fields = fields.where((field) => field.isPreference).toList();
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && request == _request && revision == _api.sessionRevision) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν τα πεδία πελάτη.';
        });
      }
    }
  }

  Future<void> _toggle(CustomerField field, bool visible) async {
    final revision = _api.sessionRevision;
    setState(() {
      _saving = field.id;
      _error = null;
    });
    try {
      await _repository.setVisible(field.id, visible);
      if (!mounted || revision != _api.sessionRevision) return;
      await _load();
    } catch (error) {
      if (mounted && revision == _api.sessionRevision) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Δεν αποθηκεύτηκε η επιλογή.',
        );
      }
    } finally {
      if (mounted && revision == _api.sessionRevision) {
        setState(() => _saving = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CustomerMergeSettings(),
              const SizedBox(height: 20),
              Text(
                'Πεδία καρτέλας πελάτη',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Επίλεξε ποια προαιρετικά πεδία χρησιμοποιεί το κατάστημά σου. Η απόκρυψη κρατά όλα τα αποθηκευμένα στοιχεία· θα εμφανιστούν ξανά όταν ενεργοποιήσεις το πεδίο.',
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: _load,
                  child: const Text('Δοκίμασε ξανά'),
                ),
              ],
              for (final group in [
                'shared',
                ..._fields
                    .map((field) => field.group)
                    .where((group) => group != 'shared')
                    .toSet(),
              ]) ...[
                Text(
                  group == 'shared'
                      ? 'Κοινές προτιμήσεις'
                      : 'Πεδία τύπου καταστήματος',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: _fields
                        .where((field) => field.group == group)
                        .map(
                          (field) => SwitchListTile(
                            title: Text(field.label),
                            subtitle: Text(
                              field.active
                                  ? 'Εμφανίζεται στην καρτέλα'
                                  : 'Κρυφό — τα στοιχεία διατηρούνται',
                            ),
                            value: field.active,
                            onChanged: _saving != null
                                ? null
                                : (visible) => _toggle(field, visible),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
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
