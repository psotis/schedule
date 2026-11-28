import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/customer_merge_repository.dart';

class CustomerMergeDialog extends StatefulWidget {
  const CustomerMergeDialog({
    super.key,
    required this.source,
    required this.apiClient,
  });
  final Map<String, dynamic> source;
  final ApiClient apiClient;
  @override
  State<CustomerMergeDialog> createState() => _CustomerMergeDialogState();
}

class _CustomerMergeDialogState extends State<CustomerMergeDialog> {
  late final CustomerMergeRepository _repository;
  late final int _revision;
  late final StreamSubscription<int> _session;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _target, _preview;
  bool _loading = true, _busy = false, _confirmed = false;
  String? _error;
  String _name(Map<String, dynamic> customer) =>
      '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
  String _normalize(String value) {
    const accented = 'άέήίόύώϊΐϋΰς';
    const plain = 'αεηιουωιιυυσ';
    var result = value.toLowerCase();
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  void initState() {
    super.initState();
    _repository = CustomerMergeRepository(apiClient: widget.apiClient);
    _revision = widget.apiClient.sessionRevision;
    _session = widget.apiClient.sessionChanges.listen((_) {
      if (mounted) Navigator.pop(context);
    });
    _search.text = _name(widget.source);
    _load();
  }

  bool get _current => mounted && _revision == widget.apiClient.sessionRevision;
  Future<void> _load() async {
    try {
      final customers = await _repository.getCustomers();
      if (_current) {
        setState(() {
          _customers = customers
              .where((item) => item['uuid'] != widget.source['uuid'])
              .toList();
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (_current) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν οι πελάτες.';
        });
      }
    }
  }

  Future<void> _review() async {
    if (_target == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await _repository.preview(
        widget.source['uuid'].toString(),
        _target!['uuid'].toString(),
      );
      if (_current) {
        setState(() {
          _preview = preview;
          _confirmed = false;
        });
      }
    } catch (error) {
      if (_current) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Δεν φορτώθηκε η προεπισκόπηση.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _merge() async {
    final navigator = Navigator.of(context);
    if (_busy || !_confirmed || _preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _repository.merge(
        widget.source['uuid'].toString(),
        _target!['uuid'].toString(),
        _preview!['preview_token'].toString(),
      );
      if (_current) navigator.pop(result['target_uuid'].toString());
    } catch (error) {
      if (_current) {
        setState(() {
          _error = error is ApiException
              ? error.message
              : 'Δεν έγινε η συγχώνευση.';
          if (error is ApiException && error.statusCode == 409) {
            _preview = null;
            _confirmed = false;
          }
        });
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Widget _card(String title, String name, Object count) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          Text('$count ραντεβού'),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final filtered = _customers
        .where(
          (item) =>
              _normalize('${_name(item)} ${item['phone'] ?? ''}')
                  .contains(_normalize(_search.text)),
        )
        .take(30)
        .toList();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: SizedBox(
        width: 650,
        height: (MediaQuery.sizeOf(context).height - 40).clamp(280.0, 780.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Συγχώνευση καρτελών',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loading) const LinearProgressIndicator(),
                      if (_preview == null) ...[
                        Text(
                          'Καρτέλα που θα αρχειοθετηθεί: ${_name(widget.source)}',
                        ),
                        Text(
                          '${widget.source['phone'] ?? ''} · ID ${widget.source['uuid']}',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Διάλεξε την κύρια καρτέλα που θα παραμείνει. Έλεγξε τηλέφωνο και στοιχεία· το ίδιο όνομα δεν σημαίνει πάντα το ίδιο άτομο.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _search,
                          enabled: !_busy,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Αναζήτηση ονόματος / τηλεφώνου',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_loading && filtered.isEmpty)
                          const Text(
                            'Δεν βρέθηκε άλλη καρτέλα. Άλλαξε την αναζήτηση.',
                          ),
                        for (final customer in filtered)
                          Card(
                            child: ListTile(
                              selected: _target?['uuid'] == customer['uuid'],
                              leading: Icon(
                                _target?['uuid'] == customer['uuid']
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                              title: Text(_name(customer)),
                              subtitle: Text(
                                '${customer['phone'] ?? ''} · ID ${customer['uuid']}',
                              ),
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _target = customer),
                            ),
                          ),
                      ] else ...[
                        _card(
                          'Κύρια καρτέλα — παραμένει',
                          _preview!['target']['name'].toString(),
                          _preview!['target']['appointments'],
                        ),
                        _card(
                          'Δεύτερη καρτέλα — αρχειοθετείται',
                          _preview!['source']['name'].toString(),
                          _preview!['source']['appointments'],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Τα ραντεβού και οι συνδεδεμένες υπηρεσίες και πληρωμές θα εμφανίζονται στην κύρια καρτέλα. Οι σημειώσεις μεταφέρονται και τα κενά στοιχεία συμπληρώνονται. Τα αρχικά στοιχεία παραμένουν αποθηκευμένα στην αρχειοθετημένη καρτέλα.',
                        ),
                        if ((_preview!['conflicts'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Διαφορές στοιχείων — διατηρείται η τιμή της κύριας καρτέλας:',
                          ),
                          for (final conflict in _preview!['conflicts'] as List)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '${conflict['label']}: ${conflict['target']} ← ${conflict['source']}',
                              ),
                            ),
                        ],
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Επιβεβαιώνω ότι οι δύο καρτέλες αφορούν το ίδιο άτομο.',
                          ),
                          value: _confirmed,
                          onChanged: _busy
                              ? null
                              : (value) =>
                                    setState(() => _confirmed = value == true),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (_preview == null) {
                              Navigator.pop(context);
                            } else {
                              setState(() {
                                _preview = null;
                                _confirmed = false;
                              });
                            }
                          },
                    child: Text(_preview == null ? 'Άκυρο' : 'Πίσω'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy || _loading
                        ? null
                        : (_preview == null
                              ? (_target == null ? null : _review)
                              : (_confirmed ? _merge : null)),
                    icon: const Icon(Icons.merge_type),
                    label: Text(
                      _busy
                          ? 'Παρακαλώ περίμενε…'
                          : (_preview == null ? 'Προεπισκόπηση' : 'Συγχώνευση'),
                    ),
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
    _search.dispose();
    _session.cancel();
    super.dispose();
  }
}
