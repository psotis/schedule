import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/screens/responsive_ui/mobile/employee/widgets/employee_card.dart';
import 'package:scheldule/utils/custom_text_form.dart';

import '../../../../../models/employee.dart';

class EmployeeList extends StatefulWidget {
  final User? user;
  const EmployeeList({super.key, this.user});

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  String? userId;
  late final stream = EmployeeRepository().streamEmployee(userId: userId!);
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
          width: MediaQuery.of(context).size.width * .8,
          child: CustomTextForm(
            labelText: 'Αναζήτηση',
            hintText: 'Ονοματεπώνυμο εργαζομένου',
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

                final filteredEmployee = snapshot.data!.where((employee) {
                  final fullName =
                      '${employee.name} ${employee.surname}'.toLowerCase();
                  return fullName.contains(_searchTerm.toLowerCase());
                }).toList();

                return isListView
                    ? _buildListView(filteredEmployee)
                    : _buildGridView(filteredEmployee);
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

  ListView _buildListView(List<Employee> employee) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      // shrinkWrap: true,
      itemCount: employee.length,
      itemBuilder: (BuildContext context, int index) {
        var employe = employee[index];

        return Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeCard(
                      employe: employe,
                      user: widget.user,
                      title: 'Employee Details'),
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
                    SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${employe.name} ${employe.surname}',
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
                                  employe.email,
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
                                  employe.phone,
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

  Widget _buildGridView(List<Employee> employee) {
    return GridView.builder(
      padding: EdgeInsets.all(30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
        mainAxisExtent: 180,
      ),
      itemCount: employee.length,
      itemBuilder: (context, index) {
        var employe = employee[index];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeCard(
                  employe: employe,
                  user: widget.user,
                  title: 'Employee Details',
                ),
              )),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(child: Icon(Icons.person)),
                  SizedBox(height: 12),
                  Text(
                    '${employe.name} ${employe.surname}',
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
                          employe.email,
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
                          employe.phone,
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
        );
      },
    );
  }
}
