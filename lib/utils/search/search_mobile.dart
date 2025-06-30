import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/utils/search/search_dialog.dart';

import '../../../providers/providers.dart';

enum SelectSearchMob { customer, employee }

class SearchMobile extends StatefulWidget {
  final User? user;
  final double width;
  final void Function(String, String)? setAppointment;
  final SelectSearchMob? selectSearch;

  const SearchMobile({
    super.key,
    this.user,
    required this.width,
    this.setAppointment,
    this.selectSearch,
  });

  @override
  State<SearchMobile> createState() => _SearchMobileState();
}

class _SearchMobileState extends State<SearchMobile> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectSearch == SelectSearchMob.customer) {
        context.read<SearchUserProvider>().searchUsers(user: widget.user!.uid);
      } else {
        context.read<EmployeeProvider>().searchEmployee(user: widget.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openSearchDialog() async {
    final List<dynamic> data = widget.selectSearch == SelectSearchMob.customer
        ? context.read<SearchUserProvider>().appointment
        : context.read<EmployeeProvider>().employees;

    final selected = await showDialog(
      context: context,
      builder: (context) => SearchDialog(
        title: widget.selectSearch == SelectSearchMob.customer
            ? 'Επιλογή πελάτη'
            : 'Επιλογή εργαζομένου',
        items: data,
      ),
    );

    if (selected != null) {
      _search.text = '${selected.name} ${selected.surname}';
      widget.setAppointment?.call(selected.name, selected.surname);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _search,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.selectSearch == SelectSearchMob.customer
              ? 'Αναζήτηση πελάτη'
              : 'Επέλεξε εργαζόμενο',
          suffixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onTap: _openSearchDialog,
      ),
    );
  }
}
