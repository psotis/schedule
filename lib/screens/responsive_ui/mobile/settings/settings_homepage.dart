import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          onPressed: () => context.read<ThemeProvider>().changeTheme(),
          child: Text('Change Theme')),
    );
  }
}
