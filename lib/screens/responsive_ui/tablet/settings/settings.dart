import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/themes/theme_status.dart';
import 'package:scheldule/utils/send_button.dart';

class Settings extends StatelessWidget {
  final User? user;
  const Settings({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    var switchTheme = context.watch<ThemeProvider>().state?.themeStatus;
    return Center(
      child: SendButton(
        onPressed: ()
            //  async
            {
          // context
          //     .read<DrawerProvider>()
          //     .changePage(DrawerStatus.calendar, 'calendar');
          // await Future.delayed(Duration(microseconds: 100));
          // ignore: use_build_context_synchronously
          context.read<ThemeProvider>().changeTheme();
        },
        text: 'Change Theme',
        icon: switchTheme == ThemeStatus.dark
            ? Icons.light_mode
            : Icons.dark_mode,
      ),
    );
  }
}
