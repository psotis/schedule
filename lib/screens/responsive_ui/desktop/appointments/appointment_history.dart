import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/appointment/appointment_status.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/cutom_text.dart';
import 'package:scheldule/utils/snackbar.dart';

class AppointmentHistory extends StatefulWidget {
  final User? user;
  const AppointmentHistory({super.key, this.user});

  @override
  State<AppointmentHistory> createState() => _AppointmentHistoryState();
}

class _AppointmentHistoryState extends State<AppointmentHistory> {
  TextEditingController _datePicker = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  DateTime? finalDate;
  String? formattedTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    formattedTime = DateFormat('dd-MM-yyyy').format(now);
    _datePicker = TextEditingController(text: formattedTime);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initHistory();
    });
  }

  void initHistory() {
    context
        .read<AppointmentProvider>()
        .getAppointMentsByDate(userid: widget.user!.uid, date: DateTime.now());
  }

  Future pickDate() async {
    DateTime? date = await pickDates();
    if (date == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
    );
    setState(() {
      finalDate = dateTime;
      formattedTime = DateFormat('dd-MM-yyyy').format(finalDate!);
      _datePicker.text = formattedTime!;
    });

    await context
        .read<AppointmentProvider>()
        .getAppointMentsByDate(userid: widget.user!.uid, date: date);
  }

  Future<DateTime?> pickDates() {
    return showDatePicker(
      locale: Locale('el'),
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2070),
    );
  }

  @override
  void dispose() {
    _datePicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        spacing: 20,
        children: [
          SizedBox(
            width: 350,
            child: InkWell(
              onTap: () => pickDate(),
              child: IgnorePointer(
                child: CustomTextForm(
                  controller: _datePicker,
                  readOnly: true,
                  labelText: 'Ημερομηνία',
                  hintText: '10-10-2020',
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<AppointmentProvider>(
              builder: (context, state, child) {
                if (state.appointmentState.appointmentStatus ==
                    AppointmentStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.appointmentState.appointmentStatus ==
                    AppointmentStatus.empty) {
                  return const Center(
                    child: CustomText(
                      text: 'Καμία καταχώρηση',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }

                if (state.appointmentState.appointmentStatus ==
                    AppointmentStatus.error) {
                  return const Center(
                    child: Text('Κάτι πήγε στραβά. Δοκίμασε ξανά'),
                  );
                }

                int todaysIncome = 0;
                for (var i = 0; i < state.appointmentsByDate.length; i++) {
                  todaysIncome += state.appointmentsByDate[i].paid ?? 0;
                }

                return SingleChildScrollView(
                  child: Column(
                    spacing: 20,
                    children: [
                      CustomText(
                        text: 'Ημερήσιο Εισόδημα: $todaysIncome €',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                      ...state.appointmentsByDate.map((appointment) {
                        return Center(
                          child: SizedBox(
                            width: 650,
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                title: Text(
                                  '${appointment.name} ${appointment.surname}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                leading: Text(
                                  DateFormat('dd-MM-yyyy HH:mm')
                                      .format(appointment.date!.toDate()),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appointment.employee ?? '',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        'Πλήρωσε:',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: SizedBox(
                                          width: 40,
                                          child: TextFormField(
                                            initialValue:
                                                appointment.paid?.toString() ??
                                                    '',
                                            keyboardType: TextInputType.number,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 4),
                                            ),
                                            onFieldSubmitted: (value) async {
                                              final newPaid =
                                                  int.tryParse(value);
                                              if (newPaid != null) {
                                                await context
                                                    .read<
                                                        AddAppointmentProvider>()
                                                    .editAppointment(context,
                                                        appointmentId:
                                                            appointment.id,
                                                        name: appointment.name,
                                                        surname:
                                                            appointment.surname,
                                                        date: appointment.date!,
                                                        employee: appointment
                                                            .employee,
                                                        position: appointment
                                                            .position,
                                                        paid: newPaid,
                                                        userUid:
                                                            widget.user!.uid);
                                                snackBarDialog(context,
                                                    color: Colors.blueGrey,
                                                    message:
                                                        'Ποσό ενημερώθηκε');
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '€',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          appointment.position ?? '',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}
