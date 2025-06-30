// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import 'package:scheldule/utils/check_box.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/cutom_text.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/utils/snackbar.dart';

import '../../../../../providers/search user/search_user_provider.dart';
import '../../../../../repositories/search_edit_user_repository.dart';

class CustomerCard extends StatefulWidget {
  final AppointMent customer;
  final User? user;
  const CustomerCard({
    super.key,
    required this.customer,
    this.user,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  bool? heart,
      breathe,
      sugar,
      ypertash,
      neuro,
      orthopedic,
      selfCare,
      helpCare,
      disabled,
      good,
      medium,
      bad,
      yes,
      no;
  String? name,
      surname,
      email,
      phone,
      address,
      description,
      amka,
      owes,
      birthday,
      allo,
      startingDate,
      mainIssue,
      doctor,
      surgeryPast,
      surgeryNow,
      pharmacy,
      allergies,
      spot,
      missFunctions;
  int appointmentLength = 0;
  final _formKey = GlobalKey<FormState>();
  final DateTime? date = DateTime.now();
  String? descriptionDate;

  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  @override
  void initState() {
    seeApp();
    _scrollController.addListener(_scrollListener);
    inializeBooleans();
    super.initState();
  }

  void inializeBooleans() {
    heart = widget.customer.heart ?? false;
    breathe = widget.customer.breathe ?? false;
    sugar = widget.customer.sugar ?? false;
    ypertash = widget.customer.ypertash ?? false;
    neuro = widget.customer.neuro ?? false;
    orthopedic = widget.customer.orthopedic ?? false;
    selfCare = widget.customer.selfCare ?? false;
    helpCare = widget.customer.helpCare ?? false;
    disabled = widget.customer.disabled ?? false;
    good = widget.customer.good ?? false;
    medium = widget.customer.medium ?? false;
    bad = widget.customer.bad ?? false;
    yes = widget.customer.yes ?? false;
    no = widget.customer.no ?? false;
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible && _scrollController.offset <= 10) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  void _submit() async {
    if (mounted) {
      setState(() {
        autovalidateUser = AutovalidateMode.always;
      });
    }

    setState(() {
      descriptionDate = DateFormat("dd-MM-yyyy HH:mm").format(date!);
    });

    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();

    await context.read<SearchUserProvider>().editUser(
          name: name!,
          surname: surname!,
          phone: phone!,
          email: email!,
          address: address!,
          description: description!.isEmpty
              ? description!
              : "$descriptionDate:  $description",
          amka: amka!,
          owes: owes!,
          userUid: widget.user!.uid,
          docId: widget.customer.id,
          heart: heart!,
          breathe: breathe,
          sugar: sugar,
          ypertash: ypertash,
          neuro: neuro,
          orthopedic: orthopedic,
          selfCare: selfCare,
          helpCare: helpCare,
          disabled: disabled,
          good: good,
          medium: medium,
          bad: bad,
          yes: yes,
          no: no,
          birthday: birthday,
          allo: allo,
          startingDate: startingDate,
          mainIssue: mainIssue,
          doctor: doctor,
          surgeryPast: surgeryPast,
          surgeryNow: surgeryNow,
          pharmacy: pharmacy,
          allergies: allergies,
          spot: spot,
          missFunctions: missFunctions,
        );
  }

  void _removeUser({required String userId, required String userDoc}) async {
    await context
        .read<SearchUserProvider>()
        .deleteUsers(userId: userId, userDoc: userDoc);
  }

  void seeApp() async {
    var length = await SearchEditUserRepository().patientAppointmentLength(
      userId: widget.user!.uid,
      name: widget.customer.name,
      surename: widget.customer.surname,
    );
    setState(() {
      appointmentLength = length;
    });
  }

  void hideScreen() async {
    context.read<ToggleScreenProvider>().showInitialScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final descriptions = (widget.customer.description ?? [])
        .where((desc) => desc.trim().isNotEmpty)
        .toList();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Συνολικά ραντεβού: "),
                      Text(appointmentLength.toString()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _form(context),
                  const SizedBox(height: 20),
                  _descriptionList(descriptions),
                ],
              ),
            ),
          ),
          // FAB/buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: AnimatedOpacity(
              opacity: _isFabVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Center(child: _buttons(context)),
            ),
          ),
        ],
      ),
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

  Row _buttons(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        SendButton(
          onPressed: () async {
            _removeUser(
              userId: widget.user!.uid,
              userDoc: widget.customer.id,
            );

            hideScreen();
            snackBarDialog(context,
                color: Colors.red,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} διαγράφθηκε');
          },
          text: 'Διαγραφή',
          backgroundColor: Colors.red,
          icon: Icons.delete,
        ),
        SendButton(
          onPressed: () async {
            _submit();
            hideScreen();

            snackBarDialog(context,
                color: Colors.orange,
                message:
                    'Ο πελάτης ${widget.customer.name} ${widget.customer.surname} ανανεώθηκε');
          },
          text: 'Αποστολή',
          icon: Icons.edit,
          backgroundColor: Colors.orange,
        ),
      ],
    );
  }

  Padding _form(BuildContext context) {
    return Padding(
      padding: widget.user?.email == 'physiocure.oe@gmail.com'
          ? EdgeInsets.only(top: 20, left: 20, right: 20)
          : EdgeInsets.only(top: 20),
      child: SizedBox(
        width: widget.user?.email == 'physiocure.oe@gmail.com' ? null : 500,
        // height: MediaQuery.of(context).size.height * .65,
        child: Form(
          key: _formKey,
          child: widget.user?.email == 'physiocure.oe@gmail.com'
              ? Column(
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
                            labelText: 'Email',
                            hintText: 'example@gmail.com',
                            prefixIcon: Icons.email,
                            initial: widget.customer.email,
                            onSaved: (val) {
                              email = val;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Τηλέφωνο',
                            hintText: '6900000000',
                            prefixIcon: Icons.phone,
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
                            labelText: 'Διεύθυνση',
                            hintText: 'Agiou Nikolaou, Patra',
                            prefixIcon: Icons.home,
                            initial: widget.customer.address,
                            onSaved: (val) {
                              address = val;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'ΑΜΚΑ',
                            hintText: '800000000',
                            prefixIcon: Icons.numbers,
                            initial: widget.customer.address,
                            onSaved: (val) {
                              amka = val;
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
                            labelText: 'Ημ. Γέννησης',
                            hintText: '16/06/1993',
                            prefixIcon: Icons.date_range,
                            initial: widget.customer.birthday,
                            onSaved: (val) {
                              birthday = val;
                            },
                          ),
                        ),
                        Flexible(
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
                      ],
                    ),
                    // *************** Checkboxes ****************
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomCheckbox(
                          value: heart!,
                          onChanged: (newValue) =>
                              setState(() => heart = newValue),
                          label: "Καρδιολογικά ",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: breathe!,
                          onChanged: (newValue) =>
                              setState(() => breathe = newValue),
                          label: "Αναπνευστικά ",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: sugar!,
                          onChanged: (newValue) =>
                              setState(() => sugar = newValue),
                          label: "Διαβήτης",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    // *************** Checkboxes ****************
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomCheckbox(
                          value: ypertash!,
                          onChanged: (newValue) =>
                              setState(() => ypertash = newValue),
                          label: "Υπέρταση",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: neuro!,
                          onChanged: (newValue) =>
                              setState(() => neuro = newValue),
                          label: "Νευρολογικά",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: orthopedic!,
                          onChanged: (newValue) =>
                              setState(() => orthopedic = newValue),
                          label: "Ορθοπεδικά",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Άλλο',
                            hintText: 'Άλλο',
                            prefixIcon: Icons.event,
                            initial: widget.customer.allo,
                            onSaved: (val) {
                              allo = val;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Ημ.Έναρξης Συμπτωμάτων',
                            hintText: '20/02/2025',
                            prefixIcon: Icons.calendar_month,
                            initial: widget.customer.startingDate,
                            onSaved: (val) {
                              startingDate = val;
                            },
                          ),
                        ),
                      ],
                    ),

                    CustomTextForm(
                      labelText: 'Κύριο Πρόβλημα',
                      hintText: 'Κύριο Πρόβλημα',
                      prefixIcon: Icons.sync_problem,
                      initial: widget.customer.mainIssue,
                      onSaved: (val) {
                        mainIssue = val;
                      },
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Παραπέμπον Ιατρός',
                            hintText: 'Ειδικότητα',
                            prefixIcon: Icons.person,
                            initial: widget.customer.doctor,
                            onSaved: (val) {
                              doctor = val;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Χειρουργεία (παρελθόν)',
                            hintText: 'Τύπος χειρουργείου',
                            prefixIcon: Icons.man,
                            initial: widget.customer.surgeryPast,
                            onSaved: (val) {
                              surgeryPast = val;
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
                            labelText: 'Φαρμακευτική αγωγή',
                            hintText: 'Φάρμακα',
                            prefixIcon: Icons.vaccines,
                            initial: widget.customer.pharmacy,
                            onSaved: (val) {
                              pharmacy = val;
                            },
                          ),
                        ),
                        Flexible(
                          child: CustomTextForm(
                            labelText: 'Χειρουργεία (τωρινό)',
                            hintText: 'Τύπος χειρουργείου',
                            prefixIcon: Icons.man,
                            initial: widget.customer.surgeryNow,
                            onSaved: (val) {
                              surgeryNow = val;
                            },
                          ),
                        ),
                      ],
                    ),
                    CustomTextForm(
                      labelText: 'Αλλεργίες',
                      hintText: 'Τύποι',
                      prefixIcon: Icons.man_2,
                      initial: widget.customer.allergies,
                      onSaved: (val) {
                        allergies = val;
                      },
                    ),
                    // *************** Checkboxes ****************
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                            text: 'Κίνηση:',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                        CustomCheckbox(
                          value: selfCare!,
                          onChanged: (newValue) =>
                              setState(() => selfCare = newValue),
                          label: "Αυτόνομος",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: helpCare!,
                          onChanged: (newValue) =>
                              setState(() => helpCare = newValue),
                          label: "Με βοήθεια",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: disabled!,
                          onChanged: (newValue) =>
                              setState(() => disabled = newValue),
                          label: "Καθηλωμένος",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    // *************** Checkboxes ****************
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                            text: 'Ισορροπία/Στάση:',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                        CustomCheckbox(
                          value: good!,
                          onChanged: (newValue) =>
                              setState(() => good = newValue),
                          label: "Καλή",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: medium!,
                          onChanged: (newValue) =>
                              setState(() => medium = newValue),
                          label: "Μέτρια",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: bad!,
                          onChanged: (newValue) =>
                              setState(() => bad = newValue),
                          label: "Κακή",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    // *************** Checkboxes ****************
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                            text: 'Αίσθηση πόνου:',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                        CustomCheckbox(
                          value: yes!,
                          onChanged: (newValue) =>
                              setState(() => yes = newValue),
                          label: "Ναι",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        CustomCheckbox(
                          value: no!,
                          onChanged: (newValue) =>
                              setState(() => no = newValue),
                          label: "Όχι",
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          size: 28,
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        Expanded(
                          child: CustomTextForm(
                            labelText: 'Σημείο',
                            hintText: 'Σημείο',
                            prefixIcon: Icons.sticky_note_2,
                            initial: widget.customer.spot,
                            onSaved: (val) {
                              spot = val;
                            },
                          ),
                        ),
                      ],
                    ),
                    CustomTextForm(
                      labelText: 'Κινητικάν/λειτουργικά ελλείμματα',
                      hintText: '....',
                      prefixIcon: Icons.sticky_note_2_sharp,
                      initial: widget.customer.missFunctions,
                      onSaved: (val) {
                        missFunctions = val;
                      },
                    ),

                    CustomTextForm(
                      labelText: 'Περιγραφή',
                      hintText: '...........',
                      prefixIcon: Icons.description,
                      // initial: widget.customer.description,
                      onSaved: (val) {
                        description = val;
                      },
                    ),
                  ],
                )
              : Column(
                  spacing: 15,
                  children: [
                    CustomTextForm(
                      labelText: 'Όνομα',
                      hintText: 'John',
                      prefixIcon: Icons.people,
                      initial: widget.customer.name,
                      onSaved: (val) {
                        name = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Επώνυμο',
                      hintText: 'Doe',
                      prefixIcon: Icons.people_alt,
                      initial: widget.customer.surname,
                      onSaved: (val) {
                        surname = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Email',
                      hintText: 'example@gmail.com',
                      prefixIcon: Icons.email,
                      initial: widget.customer.email,
                      onSaved: (val) {
                        email = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Τηλέφωνο',
                      hintText: '6900000000',
                      prefixIcon: Icons.phone,
                      initial: widget.customer.phone,
                      onSaved: (val) {
                        phone = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Διεύθυνση',
                      hintText: 'Agiou Nikolaou, Patra',
                      prefixIcon: Icons.home,
                      initial: widget.customer.address,
                      onSaved: (val) {
                        address = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'ΑΜΚΑ',
                      hintText: '800000000',
                      prefixIcon: Icons.numbers,
                      initial: widget.customer.address,
                      onSaved: (val) {
                        amka = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Οφειλή',
                      hintText: 'Υπόλοιπο',
                      prefixIcon: Icons.euro,
                      chooseText: ChooseText.owes,
                      initial: widget.customer.owes,
                      onSaved: (val) {
                        owes = val;
                      },
                    ),
                    CustomTextForm(
                      labelText: 'Περιγραφή',
                      hintText: '...........',
                      prefixIcon: Icons.description,
                      // initial: widget.customer.description,
                      onSaved: (val) {
                        description = val;
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
