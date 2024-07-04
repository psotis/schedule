import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/log_in/login_state.dart';

import '../../../constants/screen%20sizes/screen_sizes.dart';
import '../../../providers/providers.dart';

class LoginWidget extends StatefulWidget {
  bool isMobile;
  LoginWidget({super.key, required this.isMobile});

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
      children: [
        //* ****************** Email textfield ***************************
        SizedBox(
          height: ScreenSize.screenHeight * .1,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: TextFormField(
            style: TextStyle(color: Colors.black),
            controller: _emailController,
            decoration: InputDecoration(
              label: Text('E-mail',
                  style: TextStyle(
                    fontSize: widget.isMobile == true ? 16 : 18,
                  )),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(
                Icons.email,
                size: widget.isMobile == true ? 18 : 22,
              ),
            ),
            onChanged: (value) {
              value = _emailController.text;
              print(_emailController.text);
            },
          ),
        ),
        SizedBox(
          height: widget.isMobile == true
              ? ScreenSize.screenHeight * .03
              : ScreenSize.screenHeight * .01,
        ),
        //* ****************** Password textfield ***************************
        SizedBox(
          height: ScreenSize.screenHeight * .1,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: TextFormField(
            style: TextStyle(color: Colors.black),
            controller: _passwordController,
            obscureText: obscureText,
            decoration: InputDecoration(
              label: Text('Password',
                  style: TextStyle(
                    fontSize: widget.isMobile == true ? 16 : 18,
                  )),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(
                Icons.password,
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
              print(_passwordController.text);
            },
            onFieldSubmitted: (value) => signIn(),
          ),
        ),
        SizedBox(height: ScreenSize.screenHeight * .01),
        SizedBox(
          height: ScreenSize.screenHeight * .06,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: ElevatedButton(
            style: ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(Colors.white),
                backgroundColor: loginStatus == SigninStatus.submitting
                    ? MaterialStatePropertyAll(Colors.grey)
                    : MaterialStatePropertyAll(
                        Color.fromARGB(255, 226, 48, 24))),
            onPressed: loginStatus == SigninStatus.submitting ? null : signIn,
            child: loginStatus == SigninStatus.submitting
                ? SizedBox(
                    height: ScreenSize.screenHeight * .04,
                    width: ScreenSize.screenWidth * .03,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                      ),
                    ),
                  )
                : Text(
                    'Login',
                    style: TextStyle(
                      fontSize: widget.isMobile == true ? 16 : 18,
                    ),
                  ),
          ),
        ),
        // Flexible(
        //   flex: 2,
        //   child: SignInScreen(
        //     providerConfigs: [GoogleProviderConfiguration(clientId: '')],
        //   ),
        // ),
        SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: ScreenSize.screenHeight * .06,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: OutlinedButton(
            onPressed: () => context.read<ChangePageProvider>().changePage(),
            // onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: Text('Create Account',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: widget.isMobile == true ? 16 : 18,
                )),
          ),
        ),
      ],
    );
  }

  Future signIn() async {
    context.read<SigninProvider>().signin(
        email: _emailController.text, password: _passwordController.text);
  }
}
