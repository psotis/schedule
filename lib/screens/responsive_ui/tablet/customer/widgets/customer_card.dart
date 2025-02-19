// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:scheldule/models/appointment_model.dart';

class CustomerCard extends StatelessWidget {
  final AppointMent customer;
  const CustomerCard({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(customer.name));
  }
}
