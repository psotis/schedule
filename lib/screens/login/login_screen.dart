// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/login%20to%20sign%20up/change_page_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/screens/signup/signup_widget.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

import '../../constants/logos/photos_gifs.dart';
import '../../constants/screen%20sizes/screen_sizes.dart';
import 'widgets/login_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const mobileHeight = 600;

  bool isMobile = false;

  Future<void> _signInWithGoogle() async {
    try {
      String? storeType;
      if (context.read<ChangePageProvider>().state.changePageStatus ==
          ChangePageStatus.signup) {
        storeType = await _selectStoreType();
        if (storeType == null) return;
      }
      await context
          .read<AuthRepository>()
          .signInWithGoogle(storeType: storeType);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<String?> _selectStoreType() async {
    try {
      final response = await context.read<ApiClient>().get('/store-types');
      final storeTypes = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return null;
      return showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Select your business type'),
          children: storeTypes
              .map(
                (storeType) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    storeType['code']?.toString(),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(storeType['name']?.toString() ?? ''),
                    subtitle: Text(storeType['description']?.toString() ?? ''),
                  ),
                ),
              )
              .toList(),
        ),
      );
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load store types')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Media.back1),
              fit: BoxFit.cover,
            ),
          ),
          child: ColoredBox(
            color: const Color(0x8F052F2B),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900 &&
                      constraints.maxHeight > mobileHeight;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 36 : 16),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (wide ? 72 : 32),
                      ),
                      child: Center(
                        child: wide
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(child: _LoginIntroduction()),
                                  const SizedBox(width: 48),
                                  _authPanel(false),
                                ],
                              )
                            : _authPanel(true),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authPanel(bool mobile) {
    return Theme(
      data: buildAppTheme(Brightness.light),
      child: Container(
        width: mobile ? double.infinity : 500,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(mobile ? 22 : 32),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(248),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3B001E1B),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mobile) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  Media.logoGif,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'My Schedule',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
            ],
            Consumer<ChangePageProvider>(
              builder: (context, state, child) =>
                  state.state.changePageStatus == ChangePageStatus.login
                      ? LoginWidget(isMobile: mobile)
                      : SignupWidget(isMobile: mobile),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ή',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: SignInButton(
                Buttons.googleDark,
                text: 'Σύνδεση με Google',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                onPressed: _signInWithGoogle,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ασφαλής πρόσβαση στο κατάστημά σου',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginIntroduction extends StatelessWidget {
  const _LoginIntroduction();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              Media.logoGif,
              width: 108,
              height: 108,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Η επιχείρησή σου,\nσε μία καθαρή εικόνα.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Ραντεβού, πελάτες, ομάδα και οικονομικά σε έναν χώρο που προσαρμόζεται σε κάθε υπηρεσία.',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(Icons.event_available, 'Έξυπνα ραντεβού'),
              _FeatureChip(Icons.people_alt_outlined, 'Πελατολόγιο'),
              _FeatureChip(Icons.query_stats_rounded, 'Αναφορές'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class EntryGif extends StatelessWidget {
  double? height;
  double? width;
  EntryGif({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
        image: DecorationImage(
            image: AssetImage(
              Media.logoGif,
            ),
            fit: BoxFit.fill),
      ),
    );
  }
}
