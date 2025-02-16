import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DesktopHomepage extends StatelessWidget {
  final User? user;
  const DesktopHomepage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            child: Container(
              color: Colors.red,
            ),
          ),
          Flexible(
            child: Container(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
