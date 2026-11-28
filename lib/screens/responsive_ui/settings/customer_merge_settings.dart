import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/customer_merge_repository.dart';

import '../customer/customer_merge_notice_listener.dart';

class CustomerMergeSettings extends StatefulWidget {
  const CustomerMergeSettings({super.key});
  @override
  State<CustomerMergeSettings> createState() => _CustomerMergeSettingsState();
}

class _CustomerMergeSettingsState extends State<CustomerMergeSettings> {
  bool _enabled = false, _loading = true, _saving = false;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  late final ApiClient _api;
  StreamSubscription<int>? _sessions;
  StreamSubscription<void>? _changes;
  int _request = 0;
  CustomerMergeRepository get _repository =>
      CustomerMergeRepository(apiClient: _api);
  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _changes = _api.watch('clients').listen((_) => _load());
    _sessions = _api.sessionChanges.listen((_) {
      setState(() { _enabled = false; _loading = true; _history = []; _saving = false; _error = null; });
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    final revision = _api.sessionRevision;
    final request = ++_request;
    try {
      final values = await Future.wait<dynamic>([
        _repository.getSettings(),
        _repository.history(),
      ]);
      if (mounted && revision == _api.sessionRevision && request == _request) {
        setState(() {
          _enabled = values[0]['enabled'] == true;
          _history = values[1] as List<Map<String, dynamic>>;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && revision == _api.sessionRevision && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν οι ρυθμίσεις συγχώνευσης.';
        });
      }
    }
  }

  Future<void> _save(bool value) async {
    final revision = _api.sessionRevision;
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Αυτόματη συγχώνευση πελατών;'),
          content: const Text(
            'Θα ελεγχθούν και οι υπάρχουσες καρτέλες. Ενεργοποίησέ το μόνο αν κάθε πελάτης έχει δικό του κινητό ή email. Ίδια μη κενά στοιχεία επικοινωνίας θα ενώνουν τις καρτέλες, με διατήρηση ιστορικού και ενημέρωση. Αν υπάρχουν αντικρουόμενα στοιχεία, απαιτείται χειροκίνητος έλεγχος.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Άκυρο'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ενεργοποίηση'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true || revision != _api.sessionRevision) {
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.setEnabled(value);
      if (mounted && revision == _api.sessionRevision) await _load();
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() { _sessions?.cancel(); _changes?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Διπλές καρτέλες',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_loading) const LinearProgressIndicator(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Αυτόματη συγχώνευση'),
            subtitle: const Text(
              'Με ίδιο κινητό ή email στο ίδιο κατάστημα. Ελέγχεται κατά τη δημιουργία και την ενημέρωση πελάτη.',
            ),
            value: _enabled,
            onChanged: _loading || _saving ? null : _save,
          ),
          const Text(
            'Κενά στοιχεία δεν θεωρούνται αντιστοίχιση. Για κοινό οικογενειακό κινητό ή διαφορετικά στοιχεία, χρησιμοποίησε τη συγχώνευση με προεπισκόπηση από την καρτέλα πελάτη.',
          ),
          if (_history.isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              'Πρόσφατες συγχωνεύσεις',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final event in _history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.merge_type),
                title: Text(
                  '«${event['source_name']}» → «${event['target_name']}»',
                ),
                subtitle: Text(
                  '${mergeReasonLabel(event['reason'].toString())} · ${event['created_at'].toString().substring(0, 10)}',
                ),
              ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_error != null)
            TextButton(onPressed: _load, child: const Text('Δοκίμασε ξανά')),
        ],
      ),
    ),
  );
}
