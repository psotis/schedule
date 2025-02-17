// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Customer extends StatelessWidget {
  final User? user;
  const Customer({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Here I have to make a list with all customers, add a search field and onTap to each customer navigate to its card',
        textAlign: TextAlign.center,
      ),
    );
  }
}
