// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_add.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_list.dart';
import 'package:scheldule/screens/responsive_ui/widgets/section_tabs.dart';

class Customer extends StatefulWidget {
  const Customer({
    super.key,
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
    return SectionTabs(
      controller: _tabController!,
      tabs: const [
        SectionTabItem('Λίστα πελατών', Icons.people_alt_outlined),
        SectionTabItem('Νέος πελάτης', Icons.person_add_alt_1_rounded),
      ],
      children: const [CustomerList(), CustomerAdd()],
    );
  }
}
