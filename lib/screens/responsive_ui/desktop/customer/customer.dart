// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_add.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_card.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_list.dart';

import '../../../../constants/screen sizes/screen_sizes.dart';
import '../../../../providers/toggle_screen/toggle_screen_state.dart';

class Customer extends StatefulWidget {
  final User? user;
  const Customer({
    super.key,
    this.user,
  });

  @override
  State<Customer> createState() => _CustomerState();
}

class _CustomerState extends State<Customer>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // void _dismissKeyboard(BuildContext context) {
  //   FocusScope.of(context).requestFocus(FocusNode());
  // }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Column(
            children: [
              TabBar(controller: _tabController, tabs: [
                SizedBox(
                  height: ScreenSize.screenHeight * .08,
                  width: ScreenSize.screenWidth * .2,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Λίστα πελατών',
                    ),
                  ),
                ),
                SizedBox(
                  height: ScreenSize.screenHeight * .08,
                  width: ScreenSize.screenWidth * .2,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Προσθήκη πελάτη',
                    ),
                  ),
                ),
              ]),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Tab(
                      child: CustomerList(user: widget.user),
                    ),
                    Tab(
                      child: CustomerAdd(user: widget.user),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(),
        Flexible(child: Consumer<ToggleScreenProvider>(
          builder: (context, state, child) {
            if (state.toggleState?.toggleStatus == ToggleStatus.yes) {
              return CustomerCard(
                  customer: state.toggleState!.customer, user: widget.user);
            }
            return Container();
          },
        )),
      ],
    );
  }
}
