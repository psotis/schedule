// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:scheldule/models/app_timestamp.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/add%20appointment/add_appointment_provider.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_editor.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_history_view.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/search/search.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';
import '../../../../../repositories/search_edit_user_repository.dart';

class CustomerSide extends StatefulWidget {
  final AppointMent customer;
  final AppointMent appointMent;
  const CustomerSide({
    super.key,
    required this.customer,
    required this.appointMent,
  });

  @override
  State<CustomerSide> createState() => _CustomerSideState();
}

class _CustomerSideState extends State<CustomerSide> {
  String? name,
      surname,
      email,
      phone,
      address,
      description,
      amka,
      owes,
      employee,
      position;
  int? paid;
  int appointmentLength = 0;
  final _formKey = GlobalKey<FormState>();
  final DateTime? date = DateTime.now();
  String? descriptionDate;
  List<Employee> _availableEmployees = [];
  bool _loadingEmployees = true;

  Timestamp? timestampday;
  DateTime get selectedDateTime =>
      finalDate ?? widget.appointMent.date?.toDate() ?? DateTime.now();

  DateTime? finalDate;
  String? formattedTime;

  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    seeApp();
    _loadAvailableEmployees();
  }

  Future<bool> _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    final addProvider = context.read<AddAppointmentProvider>();
    final searchProvider = context.read<SearchUserProvider>();

    setState(() {
      descriptionDate = DateFormat("dd-MM-yyyy HH:mm").format(date!);
    });

    final userForm = _formKey.currentState;

    if (userForm == null || !userForm.validate()) return false;
    userForm.save();
    try {
      await addProvider.editAppointment(
        context,
        appointmentId: widget.appointMent.id,
        clientId: widget.appointMent.clientId,
        name: name ?? widget.appointMent.name,
        surname: surname ?? widget.appointMent.surname,
        date: timestampday ?? widget.appointMent.date!,
        employee: employee,
        position: position ?? widget.appointMent.position,
      );

      await searchProvider.editUser(
        name: name ?? widget.customer.name,
        surname: surname ?? widget.customer.surname,
        phone: phone ?? widget.customer.phone,
        email: email ?? widget.customer.email,
        address: address ?? widget.customer.address,
        description: (description == null || description!.isEmpty)
            ? ''
            : "$descriptionDate:  $description",
        amka: amka ?? widget.customer.amka,
        owes: owes ?? widget.customer.owes!,
        docId: widget.customer.id,
      );
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        snackBarDialog(context, color: Colors.red, message: error.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        snackBarDialog(
          context,
          color: Colors.red,
          message: 'Δεν ήταν δυνατή η ενημέρωση του ραντεβού',
        );
      }
      return false;
    }
  }

  Future<bool> _removeUser({required String clientId}) {
    return context.read<SearchUserProvider>().deleteUser(clientId: clientId);
  }

  void seeApp() async {
    var length =
        await context.read<SearchEditUserRepository>().patientAppointmentLength(
              name: widget.customer.name,
              clientId: widget.customer.id,
              surename: widget.customer.surname,
            );
    if (mounted) {
      setState(() {
        appointmentLength = length;
      });
    }
  }

  Future pickDateTime() async {
    DateTime? date = await pickDate();
    if (date == null) return;

    TimeOfDay? time = await pickTime();
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      finalDate = dateTime;
      formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(finalDate!);
      timestampday = Timestamp.fromDate(finalDate!);
    });
    await _loadAvailableEmployees();
  }

  Future<DateTime?> pickDate() {
    return showDatePicker(
      locale: Locale('el'),
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
  }

  Future<TimeOfDay?> pickTime() {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.dialOnly,
      context: context,
      initialTime: TimeOfDay(
        hour: selectedDateTime.hour,
        minute: selectedDateTime.minute,
      ),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Localizations.override(
          context: context,
          locale: const Locale('el', 'GR'),
          child: child!,
        ),
      ),
    );
  }

  void setEmployee(String name, String surename) {
    setState(() {
      employee = '$name $surename';
    });
  }

  Future<void> _loadAvailableEmployees() async {
    final start = (timestampday ?? widget.appointMent.date)?.toDate();
    if (start == null) return;
    if (mounted) setState(() => _loadingEmployees = true);
    try {
      final duration = widget.appointMent.effectiveDurationMinutes;
      final serviceId = widget.appointMent.serviceItems.isEmpty
          ? null
          : widget.appointMent.serviceItems.first.serviceId;
      final employees =
          await context.read<AddAppointmentRepository>().getEmployees(
                serviceId: serviceId,
                start: start,
                end: start.add(Duration(minutes: duration)),
                excludeAppointmentId: widget.appointMent.id,
              );
      if (!mounted) return;
      setState(() {
        _availableEmployees = employees;
        _loadingEmployees = false;
        if (employee != null &&
            !employees.any(
              (item) => '${item.name} ${item.surname}' == employee,
            )) {
          employee = null;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadingEmployees = false);
      snackBarDialog(context, color: Colors.red, message: error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = (widget.customer.description ?? [])
        .where((desc) => desc.trim().isNotEmpty)
        .toList();

    return AppointmentDetailFrame(
      title: '${widget.appointMent.name} ${widget.appointMent.surname}',
      subtitle:
          '${DateFormat('dd/MM/yyyy • HH:mm').format(selectedDateTime)} • ${widget.appointMent.effectiveDurationMinutes}′',
      appointmentCount: appointmentLength,
      actions: _buttons(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _form(context),
        const SizedBox(height: 24),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _descriptionList(descriptions)),
      ]),
    );
  }

  Widget _descriptionList(List<String> descriptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        descriptions.isEmpty
            ? Center(
                child: Text('Καμία περιγραφή', style: TextStyle(fontSize: 18)))
            : Center(
                child: Text('Προηγούμενες περιγραφές',
                    style: TextStyle(fontSize: 18)),
              ),
        const SizedBox(height: 10),
        ...descriptions.reversed.map((desc) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(desc),
              ),
            )),
      ],
    );
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final deleted = await _removeUser(
              clientId: widget.customer.id,
            );
            if (!context.mounted) return;
            if (!deleted) {
              snackBarDialog(context,
                  color: Colors.red,
                  message:
                      'Ο πελάτης έχει ραντεβού και δεν μπορεί να διαγραφεί');
              return;
            }
            Navigator.pop(context);
            snackBarDialog(context,
                color: Colors.red,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} διαγράφθηκε');
          },
          label: const Text('Διαγραφή πελάτη'),
          style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          icon: const Icon(Icons.person_remove_outlined, size: 18),
        ),
        FilledButton.icon(
          onPressed: () async {
            final updated = await _submit();
            if (!context.mounted || !updated) return;
            Navigator.pop(context);

            snackBarDialog(context,
                color: Colors.orange,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} ανανεώθηκε');
          },
          label: const Text('Αποθήκευση'),
          icon: const Icon(Icons.check_rounded, size: 18),
        ),
      ],
    );
  }

  Padding _form(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: SizedBox(
        // height: MediaQuery.of(context).size.height * .65,
        child: Form(
            key: _formKey,
            child: Column(
              spacing: 15,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'Όνομα',
                        hintText: 'John',
                        prefixIcon: Icons.people,
                        initial: widget.customer.name,
                        readOnly: true,
                        onSaved: (val) {
                          name = val;
                        },
                      ),
                    ),
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'Επώνυμο',
                        hintText: 'Doe',
                        prefixIcon: Icons.people_alt,
                        initial: widget.customer.surname,
                        readOnly: true,
                        onSaved: (val) {
                          surname = val;
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'ΑΜΚΑ',
                        hintText: '800000000',
                        prefixIcon: Icons.numbers,
                        initial: widget.customer.amka,
                        onSaved: (val) {
                          amka = val;
                        },
                      ),
                    ),
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'Τηλέφωνο',
                        hintText: '6900000000',
                        prefixIcon: Icons.phone,
                        readOnly: true,
                        initial: widget.customer.phone,
                        onSaved: (val) {
                          phone = val;
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'Σταθμός / χώρος',
                        hintText: 'Γραφείο/Καρέκλα/Δωμάτειο',
                        prefixIcon: Icons.numbers,
                        initial: widget.appointMent.position,
                        onSaved: (val) {
                          position = val;
                        },
                      ),
                    ),
                    Flexible(
                      child: CustomTextForm(
                        labelText: 'Υπάλληλος',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person,
                        readOnly: true,
                        initial: widget.appointMent.employee,
                      ),
                    ),
                  ],
                ),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Υπηρεσίες / εργαζόμενοι'),
                    onPressed: () async {
                      final updated = await showAppointmentEditor(
                          context, widget.appointMent);
                      if (updated == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Ολοκλήρωση / πληρωμή'),
                    onPressed: () =>
                        showAppointmentPayments(context, widget.appointMent),
                  ),
                ]),
                if (widget.appointMent.serviceItems.length > 1)
                  const Text(
                      'Επεξεργάσου τον εργαζόμενο κάθε υπηρεσίας από το κουμπί «Υπηρεσίες / εργαζόμενοι».')
                else if (_loadingEmployees)
                  const LinearProgressIndicator()
                else if (_availableEmployees.isEmpty)
                  const Text('Δεν υπάρχει διαθέσιμος εργαζόμενος αυτή την ώρα')
                else
                  LayoutBuilder(
                      builder: (context, constraints) => Search(
                            key: ValueKey(
                              '${timestampday?.toDate().toIso8601String()}-'
                              '${_availableEmployees.map((item) => item.id).join(',')}',
                            ),
                            width: constraints.maxWidth,
                            selectSearch: SelectSearch.employee,
                            employees: _availableEmployees,
                            setAppointment: (p0, p1) => setEmployee(p0, p1),
                          )),
                Row(
                  spacing: 10,
                  children: [
                    Flexible(
                      flex: 1,
                      child: CustomTextForm(
                        labelText: 'Οφειλή',
                        hintText: 'Υπόλοιπο',
                        prefixIcon: Icons.euro,
                        chooseText: ChooseText.owes,
                        initial: widget.customer.owes,
                        onSaved: (val) {
                          owes = val;
                        },
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: CustomTextForm(
                        labelText: 'Ραντεβού',
                        hintText: '6900000000',
                        prefixIcon: Icons.calendar_month,
                        readOnly: true,
                        initial: DateFormat('dd-MM-yyyy HH:mm')
                            .format(widget.appointMent.date!.toDate()),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    Flexible(
                      flex: 1,
                      child: CustomTextForm(
                        labelText: 'Πληρωμή',
                        readOnly: true,
                        hintText: 'Σημερινό πληρωτέο ποσό',
                        prefixIcon: Icons.euro,
                        chooseText: ChooseText.owes,
                        initial:
                            widget.appointMent.paidAmount.toStringAsFixed(2),
                        onSaved: (val) {
                          paid = int.tryParse(val!);
                        },
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: CustomTextForm(
                        labelText: 'Περιγραφή',
                        hintText: '...........',
                        prefixIcon: Icons.description,
                        // initial: widget.customer.description,
                        onSaved: (val) {
                          description = val;
                        },
                      ),
                    ),
                  ],
                ),
                _pickDate()
              ],
            )),
      ),
    );
  }

  Widget _pickDate() {
    return OutlinedButton.icon(
      onPressed: pickDateTime,
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text(formattedTime ?? 'Αλλαγή ημερομηνίας / ώρας'),
    );
  }
}

class AppointmentDetailFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final int appointmentCount;
  final Widget child;
  final Widget actions;

  const AppointmentDetailFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.appointmentCount,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.event_note_rounded,
                    color: colors.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('ΣΤΟΙΧΕΙΑ ΡΑΝΤΕΒΟΥ',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant, letterSpacing: .8)),
                    const SizedBox(height: 3),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ])),
              IconButton(
                  tooltip: 'Κλείσιμο',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 14),
            Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$appointmentCount συνολικά ραντεβού',
                        style: theme.textTheme.labelSmall),
                  ),
                ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24), child: child)),
        const Divider(height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: colors.surfaceContainerLow,
          child: actions,
        ),
      ])),
    );
  }
}
