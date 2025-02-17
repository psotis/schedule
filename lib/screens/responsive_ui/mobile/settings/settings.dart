import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';

class Settings extends StatelessWidget {
  final User? user;
  const Settings({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          onPressed: () => context.read<ThemeProvider>().changeTheme(),
          child: Text('Change Theme')),
    );
  }
}
