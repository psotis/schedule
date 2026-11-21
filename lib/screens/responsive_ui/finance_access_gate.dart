import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/utils/custom_text_form.dart';

class FinanceAccessGate extends StatefulWidget {
  final WidgetBuilder destinationBuilder;

  const FinanceAccessGate({
    super.key,
    required this.destinationBuilder,
  });

  @override
  State<FinanceAccessGate> createState() => _FinanceAccessGateState();
}

class _FinanceAccessGateState extends State<FinanceAccessGate> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool? _hasPin;
  bool _changingPin = false;
  bool _busy = false;
  String? _error;

  bool get _isSettingPin => _hasPin == false || _changingPin;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final hasPin =
          await context.read<TransactionRepository>().hasFinancePin();
      if (!mounted) return;
      setState(() {
        _hasPin = hasPin;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      setState(() => _error = 'Ο κωδικός πρέπει να έχει 4 έως 8 ψηφία.');
      return;
    }
    if (_isSettingPin && pin != _confirmPinController.text.trim()) {
      setState(() => _error = 'Οι δύο κωδικοί δεν ταιριάζουν.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = context.read<TransactionRepository>();
      if (_isSettingPin) {
        await repository.setFinancePin(
          currentPassword: _passwordController.text,
          pin: pin,
        );
      } else {
        await repository.verifyFinancePin(pin);
      }
      if (!mounted) return;
      if (_isSettingPin) {
        setState(() {
          _hasPin = true;
          _changingPin = false;
        });
      }
      _passwordController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: widget.destinationBuilder),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleChangePin() {
    setState(() {
      _changingPin = !_changingPin;
      _passwordController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_hasPin == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.lock_outline_rounded,
                          color: colors.onPrimaryContainer, size: 27),
                    )),
                const SizedBox(height: 20),
                Text(
                    _isSettingPin
                        ? 'Προσωπικός κωδικός οικονομικών'
                        : 'Πρόσβαση στα οικονομικά',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                    _isSettingPin
                        ? 'Επιβεβαιώστε τον κωδικό σύνδεσής σας και ορίστε έναν προσωπικό κωδικό 4 έως 8 ψηφίων.'
                        : 'Εισαγάγετε τον προσωπικό κωδικό σας για να δείτε έσοδα, έξοδα και κινήσεις.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 24),
                if (_hasPin != null) ...[
                  if (_isSettingPin) ...[
                    CustomTextForm(
                        controller: _passwordController,
                        labelText: 'Κωδικός σύνδεσης',
                        hintText: 'Ο κωδικός του λογαριασμού σας',
                        prefixIcon: Icons.password_rounded,
                        obscureText: true),
                    const SizedBox(height: 18),
                  ],
                  CustomTextForm(
                      controller: _pinController,
                      labelText: _isSettingPin
                          ? 'Νέος κωδικός οικονομικών'
                          : 'Κωδικός οικονομικών',
                      hintText: '4 έως 8 ψηφία',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      onSubmitted: (_) => _submit()),
                  if (_isSettingPin) ...[
                    const SizedBox(height: 18),
                    CustomTextForm(
                        controller: _confirmPinController,
                        labelText: 'Επιβεβαίωση κωδικού',
                        hintText: 'Επανάληψη κωδικού',
                        prefixIcon: Icons.check_circle_outline_rounded,
                        obscureText: true,
                        onSubmitted: (_) => _submit()),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: colors.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: colors.onErrorContainer))),
                          ])),
                ],
                const SizedBox(height: 22),
                if (_hasPin == null)
                  FilledButton.icon(
                      onPressed: _loadStatus,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Δοκιμή ξανά'))
                else ...[
                  FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(_busy
                          ? 'Επιβεβαίωση…'
                          : _isSettingPin
                              ? 'Αποθήκευση & συνέχεια'
                              : 'Είσοδος στα οικονομικά')),
                  if (_hasPin == true) ...[
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: _busy ? null : _toggleChangePin,
                        child: Text(_changingPin
                            ? 'Ακύρωση'
                            : 'Αλλαγή προσωπικού κωδικού')),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
