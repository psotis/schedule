import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_card.dart';
import 'package:scheldule/utils/custom_text_form.dart';

import '../../../../../repositories/search_edit_user_repository.dart';

class CustomerList extends StatefulWidget {
  final User? user;
  const CustomerList({super.key, this.user});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  String? userId;
  late final stream = SearchEditUserRepository().streamUser(userId: userId!);
  String _searchTerm = '';
  bool isListView = true;

  @override
  void initState() {
    userId = widget.user!.uid;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _switchListGrid(),
        SizedBox(
          width: 400,
          child: CustomTextForm(
            labelText: 'Αναζήτηση',
            hintText: 'Ονοματεπώνυμο πελάτη',
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final filteredCustomer = snapshot.data!.where((appointment) {
                  final fullName = '${appointment.name} ${appointment.surname}'
                      .toLowerCase();
                  return fullName.contains(_searchTerm.toLowerCase());
                }).toList();

                return isListView
                    ? _buildListView(filteredCustomer)
                    : _buildGridView(filteredCustomer);
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

  ListView _buildListView(List<AppointMent> appointment) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      // shrinkWrap: true,
      itemCount: appointment.length,
      itemBuilder: (BuildContext context, int index) {
        var customer = appointment[index];

        return Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerCard(
                    customer: customer,
                    user: widget.user,
                  ),
                )),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 650,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 70),
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
                              Flexible(
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
                              Flexible(
                                child: Text(
                                  customer.phone,
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
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

  Widget _buildGridView(List<AppointMent> appointment) {
    return GridView.builder(
      padding: EdgeInsets.all(30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        mainAxisExtent: 180,
      ),
      itemCount: appointment.length,
      itemBuilder: (context, index) {
        var customer = appointment[index];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerCard(
                  customer: customer,
                  user: widget.user,
                ),
              )),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(child: Icon(Icons.person)),
                    SizedBox(height: 12),
                    Text(
                      '${customer.name} ${customer.surname}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Flexible(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            customer.phone,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
