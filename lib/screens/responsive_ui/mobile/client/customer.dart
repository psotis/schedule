// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/providers/appointment/appointment_provider.dart';

class Customer extends StatelessWidget {
  final User? user;
  const Customer({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stream = context.watch<AppointmentProvider>().getApp(user!.uid);
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        final users = snapshot.data;
        return ListView.builder(
          itemCount: users!.length,
          itemBuilder: (BuildContext context, int index) {
            return Text(users[index].name);
          },
        );
      },
    );
  }
}
