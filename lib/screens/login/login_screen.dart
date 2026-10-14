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
        if (!mounted) return;
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
        body: Stack(
          children: [
            const Positioned.fill(child: _LoginBackdrop()),
            SafeArea(
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: wide
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      child: _Entrance(
                                        offset: Offset(-.04, 0),
                                        child: _LoginIntroduction(),
                                      ),
                                    ),
                                    const SizedBox(width: 64),
                                    _Entrance(
                                      offset: const Offset(.04, 0),
                                      child: _authPanel(false),
                                    ),
                                  ],
                                )
                              : _Entrance(
                                  offset: const Offset(0, .035),
                                  child: _authPanel(true),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
        padding: EdgeInsets.all(mobile ? 22 : 34),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(250),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE1E7EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F14213D),
              blurRadius: 42,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mobile) ...[
              Row(
                children: [
                  _BrandMark(size: 58),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Schedule',
                          style: TextStyle(
                            color: Color(0xFF14213D),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                        Text(
                          'Business workspace',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Text(
                'Καλώς ήρθες',
                style: TextStyle(
                  color: Color(0xFF14213D),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Συνδέσου για να συνεχίσεις στο workspace σου.',
                style: TextStyle(color: Color(0xFF667085), fontSize: 15),
              ),
              const SizedBox(height: 24),
            ],
            Consumer<ChangePageProvider>(
              builder: (context, state, child) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: state.state.changePageStatus == ChangePageStatus.login
                    ? LoginWidget(
                        key: const ValueKey('login'),
                        isMobile: mobile,
                      )
                    : SignupWidget(
                        key: const ValueKey('signup'),
                        isMobile: mobile,
                      ),
              ),
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
              height: 50,
              child: SignInButton(
                Buttons.googleDark,
                text: 'Σύνδεση με Google',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onPressed: _signInWithGoogle,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: Color(0xFF667085),
                ),
                SizedBox(width: 6),
                Text(
                  'Ασφαλής πρόσβαση στο κατάστημά σου',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
              ],
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
          const Row(
            children: [
              _BrandMark(size: 72),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY SCHEDULE',
                    style: TextStyle(
                      color: Color(0xFF14213D),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'BUSINESS WORKSPACE',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 38),
          const Text(
            'Η επιχείρησή σου,\nσε μία καθαρή εικόνα.',
            style: TextStyle(
              color: Color(0xFF14213D),
              fontSize: 46,
              height: 1.06,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ραντεβού, πελάτες, ομάδα και οικονομικά σε έναν χώρο που προσαρμόζεται σε κάθε υπηρεσία.',
            style: TextStyle(
              color: Color(0xFF5B6475),
              fontSize: 18,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 30),
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
        color: Colors.white.withAlpha(225),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDDE4EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F14213D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF08766D), size: 19),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF263247))),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;

  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .27),
        border: Border.all(color: const Color(0xFFDDE4EA)),
        boxShadow: const [
          BoxShadow(color: Color(0x1614213D), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .21),
        child: Image.asset(Media.logoGif, fit: BoxFit.cover),
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  final Widget child;
  final Offset offset;

  const _Entrance({required this.child, required this.offset});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
              offset.dx * 220 * (1 - value), offset.dy * 220 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F5F8),
      child: Stack(
        children: [
          Positioned(
            left: -150,
            top: -180,
            child: _BackdropOrb(
              size: 430,
              colors: const [Color(0x302B6CB0), Color(0x0808766D)],
            ),
          ),
          Positioned(
            right: -170,
            bottom: -220,
            child: _BackdropOrb(
              size: 520,
              colors: const [Color(0x2608766D), Color(0x0614213D)],
            ),
          ),
          Positioned(
            right: 120,
            top: 70,
            child: _BackdropOrb(
              size: 150,
              colors: const [Color(0x18A9B9C8), Color(0x04FFFFFF)],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _BackdropOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
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
