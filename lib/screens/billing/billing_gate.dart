import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/billing/billing_provider.dart';
import 'billing_page.dart';

class BillingGate extends StatefulWidget {
  final Widget child;
  const BillingGate({super.key, required this.child});
  @override
  State<BillingGate> createState() => _BillingGateState();
}

class _BillingGateState extends State<BillingGate> {
  String? _result;
  bool _returnHandled = false;
  bool _dismissReturn = false;
  bool _signingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final billing = context.watch<BillingProvider>();
    if (!_returnHandled && billing.canManage) {
      _returnHandled = true;
      final uri = Uri.base;
      final transaction = uri.queryParameters['t'];
      if (uri.path.startsWith('/billing/') && transaction != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await billing.repository.confirm(transaction);
            await billing.load();
            if (mounted) {
              setState(
                () =>
                    _result = 'Η πληρωμή επιβεβαιώθηκε. Η πρόσβαση ανανεώθηκε.',
              );
            }
          } catch (error) {
            if (mounted) setState(() => _result = error.toString());
          }
        });
      } else if (uri.path.endsWith('/failure')) {
        _result = 'Η πληρωμή δεν ολοκληρώθηκε. Μπορείς να προσπαθήσεις ξανά.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    if (billing.data == null) {
      return Scaffold(
        body: Center(
          child: billing.error == null
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: billing.load,
                  child: Text('${billing.error} · Ξανά'),
                ),
        ),
      );
    }
    if (!billing.canManage) {
      if (!billing.allowed && !_signingOut) {
        _signingOut = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<AuthProvider>().signout(),
        );
      }
      return billing.allowed
          ? widget.child
          : const Scaffold(
              body: Center(
                child: Text(
                  'Το κατάστημα δεν είναι διαθέσιμο. Επικοινώνησε με τον ιδιοκτήτη.',
                ),
              ),
            );
    }
    final expires = DateTime.tryParse('${billing.data?['expires_at'] ?? ''}');
    final returnPage = Uri.base.path.startsWith('/billing');
    if (!billing.allowed || (returnPage && !_dismissReturn)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rantevia · Συνδρομή'),
          actions: [
            IconButton(
              tooltip: 'Αποσύνδεση',
              onPressed: context.read<AuthProvider>().signout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_result != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(_result!)),
            if (billing.allowed)
              TextButton(
                onPressed: () => setState(() => _dismissReturn = true),
                child: const Text('Άνοιγμα εφαρμογής'),
              ),
            const Expanded(child: BillingPage()),
          ],
        ),
      );
    }
    if (billing.data?['enabled'] != true) return widget.child;
    return Column(
      children: [
        Material(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      billing.data?['status'] == 'complimentary'
                          ? 'Δωρεάν πρόσβαση'
                          : expires == null
                              ? 'Ενεργή πρόσβαση'
                              : 'Λήξη πρόσβασης: ${DateFormat('dd/MM/yyyy').format(expires.toLocal())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 1000,
                          height: MediaQuery.sizeOf(context).height * .9,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                              const Expanded(child: BillingPage()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Συνδρομή'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
