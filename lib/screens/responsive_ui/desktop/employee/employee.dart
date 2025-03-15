// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_state.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/widgets/employee_add.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/widgets/employee_card.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/widgets/employee_list.dart';

import '../../../../constants/screen sizes/screen_sizes.dart';

class Employee extends StatefulWidget {
  final User? user;
  const Employee({
    super.key,
    this.user,
  });

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ToggleScreenProvider>().showInitialScreen(),
      child: Row(
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
                        'Λίστα εργαζομένων',
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ScreenSize.screenHeight * .08,
                    width: ScreenSize.screenWidth * .2,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Προσθήκη εργαζόμενου',
                      ),
                    ),
                  ),
                ]),
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Tab(
                        child: EmployeeList(user: widget.user),
                      ),
                      Tab(
                        child: EmployeeAdd(user: widget.user),
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
                return EmployeeCard(
                  employe: state.toggleState!.employee,
                  user: widget.user,
                );
              }
              return Container();
            },
          )),
        ],
      ),
    );
  }
}
