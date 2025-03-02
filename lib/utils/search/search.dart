// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/providers.dart';

enum SelectSearch { customer, employee }

// ignore: must_be_immutable
class Search extends StatefulWidget {
  User? user;
  final double width;
  final void Function(String, String)? setAppointment;
  SelectSearch? selectSearch;
  Search({
    super.key,
    this.user,
    required this.width,
    this.setAppointment,
    this.selectSearch,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsers();
      fetchEmployees();
    });
    super.initState();
  }

  void fetchUsers() {
    context.read<SearchUserProvider>().searchUsers(user: widget.user!.uid);
  }

  void fetchEmployees() {
    context.read<EmployeeProvider>().searchEmployee(user: widget.user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    var searchUser = context.watch<SearchUserProvider>().appointment;
    var employee = context.watch<EmployeeProvider>().employees;
    return widget.selectSearch == SelectSearch.customer
        ? DropdownMenu(
            menuStyle: MenuStyle(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)))),
            ),
            width: widget.width,
            label: Text('Αναζήτηση πελάτη'),
            enableFilter: true,
            enableSearch: true,
            dropdownMenuEntries: searchUser.map((e) {
              return DropdownMenuEntry(
                value: e,
                label: '${e.name} ${e.surname}',
                leadingIcon: Icon(Icons.person_outline),
                style: ButtonStyle(
                  elevation: WidgetStatePropertyAll(4),
                  animationDuration: Duration(microseconds: 200),
                  padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)))),
                ),
              );
            }).toList(),
            onSelected: (val) => widget.setAppointment!(val!.name, val.surname),
          )
        : DropdownMenu(
            menuStyle: MenuStyle(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)))),
            ),
            width: widget.width,
            label: Text('Επέλεξε εργαζόμενο'),
            enableFilter: true,
            enableSearch: true,
            dropdownMenuEntries: employee.map((e) {
              return DropdownMenuEntry(
                value: e,
                label: '${e.name} ${e.surname}',
                leadingIcon: Icon(Icons.person_outline),
                style: ButtonStyle(
                  elevation: WidgetStatePropertyAll(4),
                  animationDuration: Duration(microseconds: 200),
                  padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)))),
                ),
              );
            }).toList(),
            onSelected: (val) => widget.setAppointment!(val!.name, val.surname),
          );
  }
}
