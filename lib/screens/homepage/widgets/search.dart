import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/search%20user/search_user_status.dart';

import '../../../constants/screen sizes/screen_sizes.dart';
import '../../../providers/providers.dart';
import '../../../widgets/see_edit_user.dart';

// ignore: must_be_immutable
class Search extends StatefulWidget {
  User? user;
  Search({super.key, this.user});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  var selectedUser;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Center(
        child: Consumer<SearchUserProvider>(
          builder: (context, value, child) {
            if (value.searchUserState.searchUserStatus ==
                SearchUserStatus.empty) {
              return Text('Καταχώρησε ασθενή');
            }
            if (value.searchUserState.searchUserStatus ==
                SearchUserStatus.loadedList) {
              return ListView.builder(
                itemCount: value.appointment.length,
                itemBuilder: (context, index) {
                  var p = value.appointment[index];
                  print('This is the docId of search ${p.id}');

                  return DropdownMenu(
                    menuHeight: ScreenSize.screenHeight * .4,
                    inputDecorationTheme:
                        InputDecorationTheme(border: InputBorder.none
                            // OutlineInputBorder(
                            //     borderRadius:
                            //         BorderRadius.all(Radius.circular(10)))
                            ),
                    textStyle: TextStyle(fontSize: 14),
                    label: Text('Αναζήτηση',
                        style: TextStyle(fontSize: 12, color: Colors.black)),
                    enableFilter: true,
                    enableSearch: true,
                    dropdownMenuEntries: value.appointment.map((e) {
                      return DropdownMenuEntry(
                          value: e, label: '${e.name} ${e.surname}');
                    }).toList(),
                    onSelected: (val) {
                      setState(() {
                        selectedUser = val;
                      });
                      showAdaptiveDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              child: SeeEditUser(
                                list: selectedUser,
                                user: widget.user,
                              ),
                            );
                          });
                    },
                  );
                },
              );
            }
            return SizedBox();
          },
        ),
      ),
    );
  }
}
