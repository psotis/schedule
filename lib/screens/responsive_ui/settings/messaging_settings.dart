import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/store_repository.dart';
import 'package:scheldule/utils/custom_text_form.dart';

class MessagingSettings extends StatefulWidget {
  const MessagingSettings({super.key});
  @override
  State<MessagingSettings> createState() => _MessagingSettingsState();
}

class _MessagingSettingsState extends State<MessagingSettings> {
  final _form = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _apiKey = TextEditingController();
  final _secret = TextEditingController();
  final _service = TextEditingController();
  final _sender = TextEditingController();
  bool _loading = true,
      _busy = false,
      _configured = false,
      _enabled = false,
      _ready = false;
  int _hours = 24;
  String? _error;
  StoreRepository get _repository =>
      StoreRepository(apiClient: context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_account, _apiKey, _secret, _service, _sender]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getMessagingSettings();
      if (!mounted) return;
      setState(() {
        _account.text = (data['account_sid'] ?? '').toString();
        _apiKey.text = (data['api_key_sid'] ?? '').toString();
        _service.text = (data['messaging_service_sid'] ?? '').toString();
        _sender.text = (data['sender'] ?? '').toString();
        _configured = data['configured'] == true;
        _enabled = data['enabled'] == true;
        _ready = data['encryption_ready'] == true;
        _hours = (data['reminder_hours'] as num?)?.toInt() ?? 24;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Δεν φορτώθηκαν οι ρυθμίσεις SMS.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.saveMessagingSettings({
        'provider': 'twilio',
        'account_sid': _account.text.trim(),
        'api_key_sid': _apiKey.text.trim(),
        if (_secret.text.isNotEmpty) 'api_secret': _secret.text,
        'messaging_service_sid': _service.text.trim(),
        'sender': _sender.text.trim(),
        'enabled': _enabled,
        'reminder_hours': _hours,
      });
      if (!mounted) return;
      _secret.clear();
      setState(() => _configured = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Οι ρυθμίσεις Twilio αποθηκεύτηκαν.')),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Δεν αποθηκεύτηκαν οι ρυθμίσεις.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Αφαίρεση σύνδεσης Twilio;'),
        content: const Text(
          'Θα διαγραφούν τα αποθηκευμένα κλειδιά και θα σταματήσουν οι νέες αποστολές SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ακύρωση'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Αφαίρεση'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.removeMessagingSettings();
      if (mounted) {
        _secret.clear();
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Δεν αφαιρέθηκε η σύνδεση.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _link(String label, String url) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.open_in_new, size: 17),
      label: Text(label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'SMS υπενθυμίσεις με Twilio',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Χρησιμοποίησε τον δικό σου λογαριασμό Twilio. Οι χρεώσεις SMS γίνονται απευθείας εκεί. '
          'Τα κλειδιά ανήκουν αποκλειστικά σε αυτό το κατάστημα και αποθηκεύονται κρυπτογραφημένα.',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ρύθμιση βήμα προς βήμα',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Δημιούργησε λογαριασμό Twilio και επιβεβαίωσε τα στοιχεία σου. Για κανονική χρήση πρόσθεσε στοιχεία χρέωσης και υπόλοιπο. Στη δοκιμή μπορεί να απαιτούνται επιβεβαιωμένοι παραλήπτες.',
                ),
                _link(
                  'Δημιουργία λογαριασμού',
                  'https://www.twilio.com/try-twilio',
                ),
                const Text(
                  '2. Στο Console βρες το Account SID (AC…). Δημιούργησε Standard API Key στην περιοχή US1 και κράτησε το API Key SID (SK…) και το Secret, που εμφανίζεται μόνο μία φορά.',
                ),
                _link('Twilio Console', 'https://console.twilio.com/'),
                _link(
                  'Οδηγός API keys',
                  'https://www.twilio.com/docs/iam/api-keys',
                ),
                const Text(
                  '3. Επίλεξε αποστολέα: αριθμό Twilio με δυνατότητα SMS ή όνομα επιχείρησης έως 11 λατινικούς χαρακτήρες, π.χ. Physiocure. Το όνομα πρέπει να περιέχει γράμμα. Η διαθεσιμότητα και η έγκριση εξαρτώνται από τη χώρα παραλήπτη.',
                ),
                _link(
                  'Οδηγός ονόματος αποστολέα',
                  'https://www.twilio.com/docs/trust-hub/registrations/alphanumeric-sender-id',
                ),
                const Text(
                  '4. Προαιρετικά δημιούργησε Messaging Service και πρόσθεσε τον αριθμό ή το όνομά σου στο Sender Pool. Βάλε εδώ το Messaging Service SID (MG…). Αν το συμπληρώσεις, το Twilio επιλέγει τον αποστολέα από αυτό το service.',
                ),
                _link(
                  'Ρύθμιση Messaging Service',
                  'https://www.twilio.com/docs/messaging/tutorials/send-messages-with-messaging-services',
                ),
                const Text(
                  '5. Ενεργοποίησε στο Twilio τις χώρες στις οποίες θα στέλνεις. Καταχώρισε κινητά με κωδικό χώρας, π.χ. +3069…, και επίλεγε SMS μόνο όταν ο πελάτης έχει συμφωνήσει.',
                ),
                _link(
                  'Διεθνείς αποστολές',
                  'https://www.twilio.com/docs/messaging/guides/sending-international-sms-guide',
                ),
                _link(
                  'Χρεώσεις SMS στην Ελλάδα',
                  'https://www.twilio.com/en-us/sms/pricing/gr',
                ),
                const Text(
                  'Τα ελληνικά και τα μεγάλα μηνύματα μπορεί να χρεωθούν ως περισσότερα τμήματα SMS. Δεν χρησιμοποιούμε κοινό λογαριασμό Twilio της Rantevia.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!_ready)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Η ασφαλής αποθήκευση κλειδιών δεν έχει ρυθμιστεί στον διακομιστή.',
            ),
          ),
        Form(
          key: _form,
          child: Column(
            children: [
              CustomTextForm(
                labelText: 'Account SID',
                hintText: 'AC…',
                controller: _account,
                readOnly: _busy,
                validator: (v) =>
                    RegExp(r'^AC[0-9a-fA-F]{32}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Συμπλήρωσε έγκυρο Account SID.',
              ),
              const SizedBox(height: 16),
              CustomTextForm(
                labelText: 'API Key SID',
                hintText: 'SK…',
                controller: _apiKey,
                readOnly: _busy,
                validator: (v) =>
                    RegExp(r'^SK[0-9a-fA-F]{32}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Συμπλήρωσε έγκυρο API Key SID.',
              ),
              const SizedBox(height: 16),
              CustomTextForm(
                labelText: 'API Key Secret',
                hintText: _configured
                    ? 'Αποθηκευμένο - άφησέ το κενό για διατήρηση'
                    : 'Το Secret του API Key',
                controller: _secret,
                obscureText: true,
                readOnly: _busy,
                validator: (v) => (v?.isEmpty ?? true) && _configured
                    ? null
                    : (v?.length ?? 0) >= 20
                    ? null
                    : 'Συμπλήρωσε το API Key Secret.',
              ),
              const SizedBox(height: 16),
              CustomTextForm(
                labelText: 'Όνομα ή αριθμός αποστολέα',
                hintText: 'Physiocure ή +…',
                controller: _sender,
                readOnly: _busy,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty && _service.text.trim().isNotEmpty) {
                    return null;
                  }
                  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value) ||
                          RegExp(r'^(?=.*[A-Za-z])[A-Za-z0-9 ]{1,11}$')
                              .hasMatch(value)
                      ? null
                      : 'Βάλε όνομα έως 11 λατινικούς χαρακτήρες ή διεθνή αριθμό.';
                },
              ),
              const SizedBox(height: 16),
              CustomTextForm(
                labelText: 'Messaging Service SID (προαιρετικό)',
                hintText: 'MG…',
                controller: _service,
                readOnly: _busy,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ||
                        RegExp(r'^MG[0-9a-fA-F]{32}$').hasMatch(v!.trim())
                    ? null
                    : 'Συμπλήρωσε έγκυρο Messaging Service SID.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _hours,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Πότε αποστέλλεται η υπενθύμιση',
                ),
                items: [
                  for (final hour in [1, 2, 3, 6, 12, 24, 48, 72, 168])
                    DropdownMenuItem(
                      value: hour,
                      child: Text('$hour ώρες πριν το ραντεβού'),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _hours = value ?? 24),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ενεργοποίηση SMS για το κατάστημα'),
                subtitle: const Text(
                  'Αποστέλλονται μόνο για τα ραντεβού που επιλέγεις. Η επιλογή αποθηκεύεται με το κουμπί παρακάτω.',
                ),
                value: _enabled,
                onChanged: _busy || !_ready
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'Μήνυμα: «[Κατάστημα]: Υπενθύμιση για το ραντεβού σας στις [ημερομηνία και ώρα]. Για αλλαγή ή ακύρωση επικοινωνήστε με το κατάστημα.» '
                'Αν το ραντεβού απέχει λιγότερες ώρες από το όριο, η υπενθύμιση αποστέλλεται στον επόμενο έλεγχο. Δεν περιλαμβάνονται ιατρικές πληροφορίες.',
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy || !_ready ? null : _save,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(_busy ? 'Αποθήκευση…' : 'Αποθήκευση ρυθμίσεων'),
                  ),
                  if (_configured)
                    OutlinedButton(
                      onPressed: _busy ? null : _remove,
                      child: const Text('Αφαίρεση σύνδεσης'),
                    ),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Ανανέωση'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
