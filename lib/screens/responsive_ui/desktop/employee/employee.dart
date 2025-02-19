import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Employee extends StatelessWidget {
  final User? user;
  const Employee({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Here I have to make a list with all employees, add a search field and onTap to each employee navigate to its card',
        textAlign: TextAlign.center,
      ),
    );
  }
}
