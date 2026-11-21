import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/billing/billing_provider.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final data = billing.data;
    if (data == null) {
      return Center(
        child: billing.error == null
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: billing.load,
                child: Text('${billing.error} · Ξανά'),
              ),
      );
    }
    if (!billing.canManage) {
      return const Center(
        child: Text('Η διαχείριση πρόσβασης γίνεται από τον ιδιοκτήτη.'),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final enabled = data['enabled'] == true;
    final complimentary = data['status'] == 'complimentary';
    final expires = DateTime.tryParse('${data['expires_at'] ?? ''}');
    final plans = (data['plans'] as List? ?? []).cast<Map>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Η συνδρομή του καταστήματός σου',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !enabled
                      ? 'Δωρεάν πρόσβαση για όλους'
                      : complimentary
                          ? 'Δωρεάν πρόσβαση από τη Rantevia'
                          : data['status'] == 'trial'
                              ? 'Δοκιμή 15 ημερών'
                              : billing.allowed
                                  ? 'Ενεργή συνδρομή'
                                  : 'Επίλεξε πρόγραμμα ή δοκιμή',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (expires != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Λήξη: ${DateFormat('dd/MM/yyyy HH:mm').format(expires.toLocal())}',
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  !enabled
                      ? 'Στην αρχική διάθεση η εφαρμογή παρέχεται δωρεάν. Δεν ξεκινά δοκιμή και δεν γίνεται χρέωση.'
                      : complimentary
                          ? 'Η δωρεάν πρόσβαση ισχύει όσο την έχει παραχωρήσει ο διαχειριστής.'
                          : 'Ανανέωσε όποτε θέλεις. Ο χρόνος προστίθεται μετά την τρέχουσα λήξη. Οι εργαζόμενοι καλύπτονται από το πρόγραμμα του καταστήματος.',
                ),
              ],
            ),
          ),
        ),
        if (enabled && data['trial_available'] == true && !complimentary) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(billing.trial),
            icon: const Icon(Icons.timelapse),
            label: const Text('Έναρξη δωρεάν δοκιμής 15 ημερών'),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Προγράμματα πρόσβασης',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Εφάπαξ πληρωμή για την επιλεγμένη περίοδο. Δεν υπάρχει αυτόματη επαναλαμβανόμενη χρέωση.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final plan in plans)
              SizedBox(
                width: 260,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${plan['label']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${((plan['amount_cents'] as num) / 100).toStringAsFixed(2)} €',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: !enabled ||
                                  complimentary ||
                                  data['checkout_available'] != true ||
                                  _busy
                              ? null
                              : () => _run(() async {
                                    final url = Uri.parse(
                                      await billing.repository.checkout(
                                        '${plan['code']}',
                                      ),
                                    );
                                    if (url.scheme != 'https' ||
                                        ![
                                          'www.vivapayments.com',
                                          'demo.vivapayments.com',
                                        ].contains(url.host)) {
                                      throw StateError(
                                        'Μη έγκυρη διεύθυνση πληρωμής.',
                                      );
                                    }
                                    if (!await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                      webOnlyWindowName: '_self',
                                    )) {
                                      throw StateError(
                                        'Δεν άνοιξε η σελίδα πληρωμής.',
                                      );
                                    }
                                  }),
                          child: const Text('Συνέχεια στη Viva'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (enabled && data['checkout_available'] != true)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Οι πληρωμές μέσω Viva θα είναι διαθέσιμες μόλις ολοκληρωθεί η σύνδεση.',
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
        const SizedBox(height: 24),
        Text(
          'Πρόσφατες πληρωμές',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final payment in (data['payments'] as List? ?? []).cast<Map>())
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${payment['plan_code']} · ${((payment['amount_cents'] as num) / 100).toStringAsFixed(2)} €',
            ),
            subtitle: Text(
              payment['status'] == 'paid'
                  ? 'Πληρωμένο'
                  : payment['status'] == 'failed'
                      ? 'Αποτυχία'
                      : 'Σε αναμονή',
            ),
          ),
      ],
    );
  }
}
