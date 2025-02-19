// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/customer.dart'
    as cus;

class Customer extends StatelessWidget {
  final User? user;
  const Customer({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return cus.Customer(
      user: user,
    );
  }
}
