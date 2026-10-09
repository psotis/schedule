// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/desktop/income-expenses/inc_exp_main.dart';
import 'package:scheldule/screens/responsive_ui/finance_access_gate.dart';

class IncomeExpenses extends StatelessWidget {
  const IncomeExpenses({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FinanceAccessGate(
      destinationBuilder: (context) => const IncExpMain(),
    );
  }
}
