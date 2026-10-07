// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/device_sizes.dart';
import 'package:scheldule/providers/login%20to%20sign%20up/change_page_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/screens/signup/signup_widget.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/api_client.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight > mobileHeight &&
          constraints.maxWidth > DeviceSizes.mobileSize) {
        bool isMobile = false;
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(Media.back1), fit: BoxFit.fill)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: ScreenSize.screenHeight * .9,
                      width: ScreenSize.screenWidth * .4,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Column(
                        children: [
                          SizedBox(height: ScreenSize.screenHeight * .01),
                          EntryGif(
                            height: ScreenSize.screenHeight * .30,
                            width: ScreenSize.screenWidth * .15,
                          ),
                          SizedBox(height: ScreenSize.screenHeight * .01),
                          Consumer<ChangePageProvider>(
                              builder: (context, state, child) {
                            if (state.state.changePageStatus ==
                                ChangePageStatus.login) {
                              return LoginWidget(isMobile: isMobile);
                            } else {
                              return SignupWidget(isMobile: isMobile);
                            }
                          }),
                          SizedBox(height: ScreenSize.screenHeight * .05),
                          Text(
                            'Contact us',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: ScreenSize.screenHeight * .06,
                      width: ScreenSize.screenWidth * .30,
                      child: SignInButton(
                        Buttons.googleDark,
                        text: 'Sign in with Google',
                        onPressed: _signInWithGoogle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        bool isMobile = true;
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(Media.back1), fit: BoxFit.fill)),
              child: Center(
                child: Container(
                  height: ScreenSize.screenHeight * .9,
                  width: ScreenSize.screenWidth * .9,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // SizedBox(height: 5),
                        EntryGif(
                          height: ScreenSize.screenHeight * .35,
                          width: ScreenSize.screenWidth * .5,
                        ),
                        // SizedBox(height: ScreenSize.screenHeight * .01),
                        Consumer<ChangePageProvider>(
                            builder: (context, state, child) {
                          if (state.state.changePageStatus ==
                              ChangePageStatus.login) {
                            return LoginWidget(isMobile: isMobile);
                          } else {
                            return SignupWidget(isMobile: isMobile);
                          }
                        }),
                        SizedBox(height: ScreenSize.screenHeight * .02),
                        SizedBox(
                          height: ScreenSize.screenHeight * .06,
                          width: ScreenSize.screenWidth * .8,
                          child: SignInButton(
                              padding: EdgeInsets.all(10),
                              Buttons.googleDark,
                              text: 'Sign in with Google',
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              onPressed: _signInWithGoogle),
                        ),
                        SizedBox(height: ScreenSize.screenHeight * .02),
                        Text(
                          'Contact us',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });
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
