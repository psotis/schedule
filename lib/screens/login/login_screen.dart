// ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
// import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/constants/device_sizes.dart';
import 'package:scheldule/providers/login%20to%20sign%20up/change_page_state.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/screens/signup/widgets/signup_widget.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../constants/logos/photos_gifs.dart';
import '../../constants/screen%20sizes/screen_sizes.dart';
import 'widgets/login_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final providers = [GoogleAuthProvider()];

  static const mobileHeight = 600;

  bool isMobile = false;

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
                      height: ScreenSize.screenHeight * .3,
                      width: ScreenSize.screenWidth * .30,
                      child: SignInScreen(
                        providers: [
                          GoogleProvider(
                              clientId:
                                  '124706936019-4h1tvjmgmadgeg05mnm1oa8do9beieqo.apps.googleusercontent.com')
                        ],
                        resizeToAvoidBottomInset: true,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 5),
                        EntryGif(
                          height: ScreenSize.screenHeight * .35,
                          width: ScreenSize.screenWidth * .5,
                        ),
                        SizedBox(height: ScreenSize.screenHeight * .02),
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
                              onPressed: () => showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20))),
                                      child: SignInScreen(
                                        providers: [
                                          GoogleProvider(
                                              clientId:
                                                  '124706936019-4h1tvjmgmadgeg05mnm1oa8do9beieqo.apps.googleusercontent.com')
                                        ],
                                        resizeToAvoidBottomInset: true,
                                      ),
                                    ),
                                  )

                              //  Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (context) => SignInScreen(
                              //               providers: [
                              //                 GoogleProvider(
                              //                     clientId:
                              //                         '124706936019-4h1tvjmgmadgeg05mnm1oa8do9beieqo.apps.googleusercontent.com')
                              //               ],
                              //               resizeToAvoidBottomInset: true,
                              //             ))),
                              ),
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
