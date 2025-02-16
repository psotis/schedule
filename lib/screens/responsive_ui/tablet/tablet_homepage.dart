import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TabletHomepage extends StatelessWidget {
  final User? user;
  TabletHomepage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(),
      body: Row(
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
