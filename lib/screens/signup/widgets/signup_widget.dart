import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/screen%20sizes/screen_sizes.dart';
import '../../../providers/providers.dart';
import '../../../providers/sign_up/signup_state.dart';

class SignupWidget extends StatefulWidget {
  bool isMobile;
  SignupWidget({super.key, required this.isMobile});

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool check = false;
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    var signupStatus = context.watch<SignupProvider>().state.signupStatus;
    return Column(
      children: [
        //* ****************** Name textfield ***************************
        SizedBox(
          height: ScreenSize.screenHeight * .1,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: TextFormField(
            style: TextStyle(color: Colors.black),
            controller: _nameController,
            decoration: InputDecoration(
              label: Text('Name',
                  style: TextStyle(
                    fontSize: widget.isMobile == true ? 16 : 18,
                  )),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(
                Icons.person,
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
          ),
        ),
        SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: ScreenSize.screenHeight * .06,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: ElevatedButton(
            style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                backgroundColor: signupStatus == SignupStatus.submitting
                    ? WidgetStatePropertyAll(Colors.grey)
                    : WidgetStatePropertyAll(
                        Color.fromARGB(255, 226, 48, 24))),
            onPressed: signupStatus == SignupStatus.submitting ? null : signUp,
            child: signupStatus == SignupStatus.submitting
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
                    'Sign Up',
                    style: TextStyle(
                      fontSize: widget.isMobile == true ? 16 : 18,
                    ),
                  ),
          ),
        ),
        SizedBox(height: ScreenSize.screenHeight * .02),
        SizedBox(
          height: ScreenSize.screenHeight * .06,
          width: widget.isMobile == true
              ? ScreenSize.screenWidth * .8
              : ScreenSize.screenWidth * .3,
          child: ElevatedButton(
            onPressed: () => context.read<ChangePageProvider>().changePage(),
            child: Text('Back to login',
                style: TextStyle(
                  fontSize: widget.isMobile == true ? 16 : 18,
                )),
          ),
        ),
      ],
    );
  }

  Future signUp() async {
    context.read<SignupProvider>().signup(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}
