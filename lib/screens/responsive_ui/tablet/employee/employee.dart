// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/tablet/employee/widgets/employee_add.dart';
import 'package:scheldule/screens/responsive_ui/tablet/employee/widgets/employee_list.dart';
import 'package:scheldule/screens/responsive_ui/widgets/section_tabs.dart';

class Employee extends StatefulWidget {
  const Employee({
    super.key,
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
    return SectionTabs(
      controller: _tabController!,
      tabs: const [
        SectionTabItem('Ομάδα', Icons.badge_outlined),
        SectionTabItem('Νέος εργαζόμενος', Icons.person_add_alt_1_rounded),
      ],
      children: const [EmployeeList(), EmployeeAdd()],
    );
  }
}
