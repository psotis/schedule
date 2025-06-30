import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_card.dart';
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
  final int _itemsPerPage = 10;
  final List<AppointMent> _allCustomers = [];
  final List<AppointMent> _visibleCustomers = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    userId = widget.user!.uid;
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  void _loadMoreItems() {
    if (_isLoading) return;

    final filteredCustomers = _allCustomers.where((customer) {
      final fullName = '${customer.name} ${customer.surname}'.toLowerCase();
      return fullName.contains(_searchTerm.toLowerCase());
    }).toList();

    if (_visibleCustomers.length >= filteredCustomers.length) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      int startIndex = _visibleCustomers.length;
      int endIndex = startIndex + _itemsPerPage;

      if (endIndex > filteredCustomers.length) {
        endIndex = filteredCustomers.length;
      }

      setState(() {
        _visibleCustomers
            .addAll(filteredCustomers.sublist(startIndex, endIndex));
        _isLoading = false;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _updateVisibleCustomers() {
    final filteredCustomers = _allCustomers.where((customer) {
      final fullName = '${customer.name} ${customer.surname}'.toLowerCase();
      return fullName.contains(_searchTerm.toLowerCase());
    }).toList();

    setState(() {
      _visibleCustomers.clear();
      _visibleCustomers.addAll(filteredCustomers.take(_itemsPerPage));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateVisibleCustomers();
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

                _allCustomers.clear();
                _allCustomers.addAll(snapshot.data!);

                final filteredCustomers = _allCustomers.where((customer) {
                  final fullName =
                      '${customer.name} ${customer.surname}'.toLowerCase();
                  return fullName.contains(_searchTerm.toLowerCase());
                }).toList();

                _visibleCustomers.clear();
                _visibleCustomers.addAll(filteredCustomers);

                return isListView ? _buildListView() : _buildGridView();
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

  ListView _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      controller: _scrollController,
      itemCount: _visibleCustomers.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index < _visibleCustomers.length) {
          var customer = _visibleCustomers[index];

          return Center(
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerCard(
                      customer: customer,
                      user: widget.user,
                      title: 'Customer Details',
                    ),
                  )),
              child: Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 500,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueAccent,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 24),
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
                      Icon(Icons.arrow_forward_ios,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return _isLoading
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox();
        }
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(30),
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        mainAxisExtent: 180,
      ),
      itemCount: _visibleCustomers.length + 1,
      itemBuilder: (context, index) {
        if (index < _visibleCustomers.length) {
          var customer = _visibleCustomers[index];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerCard(
                    customer: customer,
                    user: widget.user,
                    title: 'Customer Details',
                  ),
                )),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                      Text(
                        customer.phone,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return _isLoading
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox();
        }
      },
    );
  }
}
