import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncExpMain extends StatefulWidget {
  final User? user;
  IncExpMain({super.key, this.user});

  @override
  State<IncExpMain> createState() => _IncExpMainState();
}

class _IncExpMainState extends State<IncExpMain> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
