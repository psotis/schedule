// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/models/custom_errors.dart';
import 'package:scheldule/providers/log_in/login_state.dart';
import 'package:scheldule/repositories/auth_repository.dart';

import '../../../providers/providers.dart';

class LoginWidget extends StatefulWidget {
  final bool isMobile;
  LoginWidget({
    super.key,
    required this.isMobile,
  });

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool check = false;
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    var loginStatus = context.watch<SigninProvider>().state.signinStatus;
    return Column(
      spacing: 15,
      children: [
        //* ****************** Email textfield ***************************
        SizedBox(
          // height: ScreenSize.screenHeight * .1,
          width: double.infinity,
          child: TextFormField(
            style: const TextStyle(color: Color(0xFF14213D)),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              floatingLabelStyle: const TextStyle(height: 1.2),
              prefixIcon: Icon(
                Icons.email_outlined,
                size: widget.isMobile == true ? 18 : 22,
              ),
            ),
            onChanged: (value) {
              value = _emailController.text;
            },
          ),
        ),
        //* ****************** Password textfield ***************************
        SizedBox(
          // height: ScreenSize.screenHeight * .1,
          width: double.infinity,
          child: TextFormField(
            style: const TextStyle(color: Color(0xFF14213D)),
            controller: _passwordController,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: 'Κωδικός πρόσβασης',
              floatingLabelStyle: const TextStyle(height: 1.2),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: widget.isMobile == true ? 18 : 22,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  obscureText = !obscureText;
                }),
                icon: Icon(
                  obscureText == true
                      ? Icons.visibility_off
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            onChanged: (value) {
              value = _passwordController.text;
            },
            onFieldSubmitted: (value) => signIn(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showPasswordReset,
            child: const Text('Ξέχασα τον κωδικό μου'),
          ),
        ),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: loginStatus == SigninStatus.submitting ? null : signIn,
            icon: loginStatus == SigninStatus.submitting
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              loginStatus == SigninStatus.submitting ? 'Σύνδεση...' : 'Σύνδεση',
              style: TextStyle(
                fontSize: widget.isMobile == true ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.read<ChangePageProvider>().changePage(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text('Δημιουργία λογαριασμού',
                style: TextStyle(
                  fontSize: widget.isMobile == true ? 16 : 18,
                )),
          ),
        ),
      ],
    );
  }

  Future<void> _showPasswordReset() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordResetDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );
    if (changed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ο κωδικός άλλαξε. Μπορείς τώρα να συνδεθείς.',
        ),
      ),
    );
  }

  Future signIn() async {
    try {
      await context.read<SigninProvider>().signin(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (_) {
      if (!mounted) return;
      final error = context.read<SigninProvider>().state.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _PasswordResetDialog extends StatefulWidget {
  final String initialEmail;

  const _PasswordResetDialog({required this.initialEmail});

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  late final TextEditingController _email;
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Συμπλήρωσε ένα έγκυρο email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } on CustomError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    final password = _password.text;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Ο κωδικός πρέπει να έχει 6 ψηφία.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Ο νέος κωδικός πρέπει να έχει 8 χαρακτήρες.');
      return;
    }
    if (password != _confirmPassword.text) {
      setState(() => _error = 'Οι κωδικοί δεν ταιριάζουν.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().confirmPasswordReset(
            email: email,
            code: code,
            newPassword: password,
          );
      if (mounted) Navigator.pop(context, true);
    } on CustomError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ανάκτηση κωδικού'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _email,
                enabled: !_codeSent && !_loading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                const Text(
                  'Αν υπάρχει λογαριασμός με αυτό το email, στάλθηκε '
                  'εξαψήφιος κωδικός. Λήγει σε 15 λεπτά.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  decoration: const InputDecoration(
                    labelText: 'Εξαψήφιος κωδικός',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _password,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Νέος κωδικός',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPassword,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _resetPassword(),
                  decoration: const InputDecoration(
                    labelText: 'Επιβεβαίωση κωδικού',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Άκυρο'),
        ),
        if (_codeSent)
          TextButton(
            onPressed: _loading ? null : _requestCode,
            child: const Text('Επαναποστολή'),
          ),
        FilledButton(
          onPressed: _loading
              ? null
              : _codeSent
                  ? _resetPassword
                  : _requestCode,
          child: _loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_codeSent ? 'Αλλαγή κωδικού' : 'Αποστολή κωδικού'),
        ),
      ],
    );
  }
}
