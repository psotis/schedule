import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/store_repository.dart';

class MonthlyReportSettings extends StatefulWidget {
  const MonthlyReportSettings({super.key});

  @override
  State<MonthlyReportSettings> createState() => _MonthlyReportSettingsState();
}

class _MonthlyReportSettingsState extends State<MonthlyReportSettings> {
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  bool _available = true;
  String _email = '';
  String _timezone = 'Europe/Athens';
  String? _error;

  StoreRepository get _repository =>
      StoreRepository(apiClient: context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _repository.getMonthlyReportSettings();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _enabled = settings['enabled'] == true;
        _available = settings['available'] != false;
        _email = (settings['recipient_email'] ?? '').toString();
        _timezone = (settings['timezone'] ?? 'Europe/Athens').toString();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν οι ρυθμίσεις αναφοράς.';
        });
      }
    }
  }

  Future<void> _save(bool enabled) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.saveMonthlyReportSettings(enabled);
      if (mounted) setState(() => _enabled = enabled);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Δεν αποθηκεύτηκε η επιλογή. Δοκίμασε ξανά.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Μηνιαία αναφορά με email',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Αυτόματη αποστολή PDF και CSV'),
                subtitle: Text(
                  _email.isEmpty
                      ? 'Στο email του ιδιοκτήτη του καταστήματος.'
                      : 'Παραλήπτης: $_email',
                ),
                value: _enabled,
                onChanged: _saving || (!_available && !_enabled) ? null : _save,
              ),
              if (_saving) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Την 1η κάθε μήνα στις 08:00 ($_timezone), για τα ραντεβού του προηγούμενου μήνα. '
                'Η ενεργοποίηση ξεκινά με την επόμενη προγραμματισμένη αποστολή.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Το σύνολο αφορά τις πληρωμές των συγκεκριμένων ραντεβού, '
                'όχι απαραίτητα τις εισπράξεις που έγιναν μέσα στον μήνα. '
                'Δεν αποστέλλεται αναφορά αν δεν υπάρχουν ραντεβού.',
              ),
              if (!_available)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Η αυτόματη αποστολή είναι προσωρινά απενεργοποιημένη.',
                  ),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              if (_loading == false && _email.isEmpty)
                TextButton(
                  onPressed: _load,
                  child: const Text('Δοκίμασε ξανά'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
