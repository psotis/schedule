import 'package:material_ui/material_ui.dart';
import 'package:scheldule/models/employee.dart';
import '../../../widgets/employee_details.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employe;
  final String title;
  const EmployeeCard({super.key, required this.employe, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title == 'Employee Details' ? 'Στοιχεία εργαζομένου' : title),
        ),
        body: SafeArea(
          top: false,
          child: EmployeeDetails(
            employe: employe,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
}
