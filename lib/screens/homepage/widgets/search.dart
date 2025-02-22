// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/providers.dart';

// ignore: must_be_immutable
class Search extends StatefulWidget {
  User? user;
  final double width;
  final void Function(String, String)? setAppointment;
  Search({
    super.key,
    this.user,
    required this.width,
    this.setAppointment,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  void initState() {
    fetchUsers();
    super.initState();
  }

  void fetchUsers() {
    context.read<SearchUserProvider>().searchUsers(user: widget.user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    var searchUser = context.watch<SearchUserProvider>().appointment;
    return DropdownMenu(
      width: widget.width,
      label: Text('Αναζήτηση πελάτη'),
      enableFilter: true,
      enableSearch: true,
      dropdownMenuEntries: searchUser.map((e) {
        return DropdownMenuEntry(value: e, label: '${e.name} ${e.surname}');
      }).toList(),
      onSelected: (val) => widget.setAppointment!(val!.name, val.surname),
    );
  }
}
