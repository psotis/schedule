import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/providers/search%20user/search_user_status.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_card.dart';

class CustomerList extends StatefulWidget {
  final User? user;
  const CustomerList({super.key, this.user});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  bool isListView = true;
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
    return Column(
      children: [
        _switchListGrid(),
        Expanded(
          child: Consumer<SearchUserProvider>(builder: (context, state, child) {
            if (state.searchUserState.searchUserStatus ==
                SearchUserStatus.loading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.searchUserState.searchUserStatus ==
                SearchUserStatus.loadedList) {
              return isListView ? _buildListView(state) : _buildGridView(state);
            }
            return SizedBox(
              child: Text('Please add a customer before adding an appointment'),
            );
          }),
        ),
      ],
    );
  }

  Row _switchListGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              isListView = true;
            });
          },
          icon: Icon(Icons.list, color: isListView ? Colors.blue : Colors.grey),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              isListView = false;
            });
          },
          icon: Icon(Icons.grid_view,
              color: isListView ? Colors.grey : Colors.blue),
        ),
      ],
    );
  }

  ListView _buildListView(SearchUserProvider state) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      // shrinkWrap: true,
      itemCount: state.appointment.length,
      itemBuilder: (BuildContext context, int index) {
        var customer = state.appointment[index];

        return Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerCard(customer: customer),
                )),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 50),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${customer.name} ${customer.surname}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customer.email,
                                  style: TextStyle(color: Colors.grey[800]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text(
                                customer.phone,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(SearchUserProvider state) {
    return GridView.builder(
      padding: EdgeInsets.all(30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        mainAxisExtent: 180,
      ),
      itemCount: state.appointment.length,
      itemBuilder: (context, index) {
        var customer = state.appointment[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(child: Icon(Icons.person)),
              SizedBox(height: 12),
              Text(
                '${customer.name} ${customer.surname}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    customer.email,
                    style: TextStyle(color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    customer.phone,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
