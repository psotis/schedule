import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';

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
    if (_hasPin == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasPin == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Αδυναμία φόρτωσης'),
            const SizedBox(height: 10),
            SendButton(onPressed: _loadStatus, text: 'Ξανά'),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSettingPin
                    ? 'Ορισμός προσωπικού κωδικού οικονομικών'
                    : 'Εισαγωγή κωδικού οικονομικών',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_isSettingPin) ...[
                CustomTextForm(
                  controller: _passwordController,
                  labelText: 'Κωδικός σύνδεσης',
                  hintText: 'Κωδικός σύνδεσης',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
              ],
              CustomTextForm(
                controller: _pinController,
                labelText: _isSettingPin ? 'Νέος κωδικός' : 'Κωδικός',
                hintText: '4 έως 8 ψηφία',
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              if (_isSettingPin) ...[
                const SizedBox(height: 10),
                CustomTextForm(
                  controller: _confirmPinController,
                  labelText: 'Επιβεβαίωση κωδικού',
                  hintText: 'Επανάληψη κωδικού',
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 14),
              SendButton(
                onPressed: _busy ? null : _submit,
                text: _busy
                    ? 'Αναμονή...'
                    : (_isSettingPin ? 'Αποθήκευση' : 'OK'),
              ),
              if (_hasPin == true)
                TextButton(
                  onPressed: _busy ? null : _toggleChangePin,
                  child: Text(_changingPin ? 'Ακύρωση' : 'Αλλαγή κωδικού'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
