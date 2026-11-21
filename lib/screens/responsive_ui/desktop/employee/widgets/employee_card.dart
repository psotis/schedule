import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import '../../../widgets/employee_details.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employe;
  final VoidCallback? onClose;
  const EmployeeCard({super.key, required this.employe, this.onClose});

  @override
  Widget build(BuildContext context) => EmployeeDetails(
        employe: employe,
        onClose: onClose ?? () => context.read<ToggleScreenProvider>().showInitialEmployeeScreen(),
      );
}
