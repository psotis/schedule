// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_editor.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_history_view.dart';
import 'package:scheldule/screens/responsive_ui/widgets/section_tabs.dart';

class Appointments extends StatefulWidget {
  const Appointments({
    super.key,
  });

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // void _dismissKeyboard(BuildContext context) {
  //   FocusScope.of(context).requestFocus(FocusNode());
  // }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionTabs(
      controller: _tabController!,
      tabs: const [
        SectionTabItem('Νέο', Icons.add_circle_outline_rounded),
        SectionTabItem('Ιστορικό', Icons.history_rounded),
      ],
      children: const [AppointmentEditor(), AppointmentHistoryView()],
    );
  }
}
