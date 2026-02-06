// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/desktop/income-expenses/inc_exp_main.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';

class IncomeExpenses extends StatefulWidget {
  final User? user;
  const IncomeExpenses({
    super.key,
    this.user,
  });

  @override
  State<IncomeExpenses> createState() => _IncomeExpensesState();
}

class _IncomeExpensesState extends State<IncomeExpenses> {
  TextEditingController? _controller = TextEditingController();

  @override
  void initState() {
    _controller = TextEditingController(text: '');
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: CustomTextForm(
              controller: _controller,
              labelText: 'Εισαγωγή κωδικού',
              hintText: 'Κωδικός',
              onChanged: (value) {
                setState(() {
                  _controller?.text == value;
                });
              },
            ),
          ),
          SendButton(
            onPressed: () {
              if (_controller?.text == 'maimou') {
                _controller?.clear();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncExpMain(
                      user: widget.user,
                    ),
                  ),
                );
              }
            },
            text: 'OK',
          )
        ],
      ),
    );
  }
}
