// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:material_ui/material_ui.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scheldule/styling/themes/legacy_widget_bridge.dart';
import 'package:provider/provider.dart';

import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/providers.dart';
import 'package:scheldule/utils/colors.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/utils/send_button.dart';
import 'package:scheldule/models/custom_errors.dart';
import 'package:scheldule/repositories/api_client.dart';

class EmployeeDetails extends StatefulWidget {
  final Employee employe;
  final VoidCallback onClose;

  const EmployeeDetails({
    super.key,
    required this.employe,
    required this.onClose,
  });

  @override
  State<EmployeeDetails> createState() => _EmployeeDetailsState();
}

class _EmployeeDetailsState extends State<EmployeeDetails> {
  String? name,
      surname,
      email,
      phone,
      address,
      afm,
      amka,
      specialiazation,
      contractType;

  final _formKey = GlobalKey<FormState>();

  Color _selectedColor = Colors.lime;

  AutovalidateMode autovalidateUser = AutovalidateMode.disabled;

  bool _busy = false;
  String? _error;

  void _closeEditor() => widget.onClose();

  void _success(String message) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surfaceContainerHighest,
      content: Row(children: [
        Icon(Icons.check_circle_outline, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(color: colors.onSurface))),
      ]),
    ));
  }

  String _failure(Object error) => error is CustomError
      ? error.message
      : error is ApiException
          ? error.message
          : 'Η ενέργεια δεν ολοκληρώθηκε. Δοκίμασε ξανά.';

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => autovalidateUser = AutovalidateMode.always);
    final userForm = _formKey.currentState;
    if (userForm == null || !userForm.validate()) return;
    userForm.save();
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<EmployeeProvider>().editEmployee(
        name: name ?? widget.employe.name,
        surname: surname ?? widget.employe.surname,
        phone: phone ?? widget.employe.phone,
        email: email ?? widget.employe.email,
        address: address ?? widget.employe.address,
        afm: afm ?? widget.employe.afm,
        amka: amka ?? widget.employe.amka,
        specialiazation: specialiazation ?? widget.employe.specialiazation,
        contractType: contractType ?? widget.employe.contractType,
        docId: widget.employe.id,
        color: colorToHexs(_selectedColor),
      );
      if (!mounted) return;
      _success('Τα στοιχεία του εργαζομένου αποθηκεύτηκαν.');
      _closeEditor();
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeEmployee() async {
    if (_busy) return;
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        icon: Icon(Icons.person_remove_outlined, color: colors.error),
        title: const Text('Αφαίρεση από την ομάδα;'),
        content: Text('${widget.employe.name} ${widget.employe.surname}\n\n'
            'Ο εργαζόμενος θα αφαιρεθεί από την ενεργή ομάδα. '
            'Τα προηγούμενα ραντεβού και οι πληρωμές του διατηρούνται. '
            'Η πρόσβαση τυχόν συνδεδεμένου λογαριασμού εργαζομένου στο κατάστημα απενεργοποιείται.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Ακύρωση')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Διαγραφή'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<EmployeeProvider>().deleteEmployee(employeeId: widget.employe.id);
      if (!mounted) return;
      _success('Ο εργαζόμενος αφαιρέθηκε από την ομάδα.');
      _closeEditor();
    } catch (error) {
      if (mounted) setState(() => _error = _failure(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = hexToColors(widget.employe.color) ?? Colors.lime;
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Επέλεξε χρώμα'),
          content: SingleChildScrollView(
            child: LegacyWidgetBridge(
                child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              enableAlpha: false,
              displayThumbColor: true,
              portraitOnly: true,
            )),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ακύρωση'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            if (_error != null)
              Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            Expanded(child: _form(context)),
            const SizedBox(height: 12),
            _buttons(context),
          ],
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _removeEmployee,
          label: const Text('Διαγραφή εργαζομένου'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.person_remove_outlined, size: 18),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          label: const Text('Αποθήκευση'),
          icon: const Icon(Icons.check_rounded, size: 18),
        ),
      ],
    );
  }

  Widget _form(
    BuildContext context,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 22, bottom: 8),
            child: Column(
              spacing: 20,
              children: [
                CustomTextForm(
                  labelText: 'Όνομα',
                  hintText: 'John',
                  prefixIcon: Icons.people,
                  initial: widget.employe.name,
                  onSaved: (val) {
                    name = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Επώνυμο',
                  hintText: 'Doe',
                  prefixIcon: Icons.people_alt,
                  initial: widget.employe.surname,
                  onSaved: (val) {
                    surname = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icons.email,
                  initial: widget.employe.email,
                  onSaved: (val) {
                    email = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τηλέφωνο',
                  hintText: '6900000000',
                  prefixIcon: Icons.phone,
                  initial: widget.employe.phone,
                  onSaved: (val) {
                    phone = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Διεύθυνση',
                  hintText: 'Agiou Nikolaou, Patra',
                  prefixIcon: Icons.home,
                  initial: widget.employe.address,
                  onSaved: (val) {
                    address = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΜΚΑ',
                  hintText: '800000000',
                  prefixIcon: Icons.numbers,
                  initial: widget.employe.amka,
                  onSaved: (val) {
                    amka = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'ΑΦΜ',
                  hintText: '800000000',
                  prefixIcon: Icons.description,
                  initial: widget.employe.afm,
                  onSaved: (val) {
                    afm = val;
                  },
                ),
                CustomTextForm(
                  labelText: 'Τύπος συμβολαίου',
                  hintText: 'Πλήρης απασχόλησης',
                  prefixIcon: Icons.work_history,
                  initial: widget.employe.contractType,
                  onSaved: (value) {
                    contractType = value;
                  },
                ),
                CustomTextForm(
                  labelText: 'Ειδικότητα',
                  hintText: 'Κομμωτής',
                  prefixIcon: Icons.work,
                  initial: widget.employe.specialiazation,
                  onSaved: (value) {
                    specialiazation = value;
                  },
                ),
                SendButton(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.black,
                  text: 'Χρώμα',
                  onPressed: _openColorPicker,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
