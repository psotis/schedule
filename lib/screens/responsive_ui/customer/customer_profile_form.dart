import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'customer_insights.dart';

class CustomerProfileForm extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final VoidCallback? onSaved;

  const CustomerProfileForm({super.key, this.customer, this.onSaved});

  @override
  State<CustomerProfileForm> createState() => _CustomerProfileFormState();
}

class _CustomerProfileFormState extends State<CustomerProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _source = TextEditingController();
  final _notes = TextEditingController();
  final _birthday = TextEditingController();
  final _address = TextEditingController();
  final _amka = TextEditingController();
  final _afm = TextEditingController();
  Map<String, dynamic>? _customer;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setCustomer(widget.customer);
  }

  void _setCustomer(Map<String, dynamic>? customer) {
    _customer = customer;
    _name.text = (customer?['first_name'] ?? '').toString();
    _surname.text = (customer?['last_name'] ?? '').toString();
    _phone.text = (customer?['phone'] ?? '').toString();
    _email.text = (customer?['email'] ?? '').toString();
    _source.text = (customer?['source'] ?? '').toString();
    _birthday.text = (customer?['date_of_birth'] ?? '').toString();
    _address.text = (customer?['address'] ?? '').toString();
    _amka.text = (customer?['amka'] ?? '').toString();
    _afm.text = (customer?['afm'] ?? '').toString();
    _notes.clear();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _surname,
      _phone,
      _email,
      _source,
      _notes,
      _birthday,
      _address,
      _amka,
      _afm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = context.read<ApiClient>();
    try {
      final phone = _phone.text.trim();
      if (phone.isNotEmpty) {
        final duplicate =
            await api.get('/client-duplicate', query: {'phone': phone});
        if (!mounted) return;
        if (duplicate is Map && duplicate['uuid'] != _customer?['uuid']) {
          final existing = Map<String, dynamic>.from(duplicate);
          final open = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    title:
                        const Text('Υπάρχει ήδη καρτέλα με αυτό το τηλέφωνο'),
                    content: Text(
                        '${existing['first_name']} ${existing['last_name']}'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Επιστροφή')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Άνοιγμα καρτέλας')),
                    ],
                  ));
          if (open == true && mounted) setState(() => _setCustomer(existing));
          return;
        }
      }
      final body = <String, dynamic>{
        'first_name': _name.text.trim(),
        'last_name': _surname.text.trim(),
        'phone': phone,
        'email': _email.text.trim(),
        'source': _source.text.trim(),
        'date_of_birth': _birthday.text,
        'address': _address.text.trim(),
        'amka': _amka.text.trim(),
        'afm': _afm.text.trim(),
        'client_description': _notes.text.trim(),
      };
      final response = _customer == null
          ? await api.post('/client', body: {...body, 'owes': 0})
          : await api.put('/client/${_customer!['uuid']}', body: body);
      if (!mounted) return;
      setState(() => _setCustomer(Map<String, dynamic>.from(response as Map)));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Η καρτέλα αποθηκεύτηκε.')));
      widget.onSaved?.call();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Text(_customer == null ? 'Νέος πελάτης' : 'Καρτέλα πελάτη',
                    style: Theme.of(context).textTheme.titleLarge),
                if (_customer != null)
                  SelectableText('Customer ID: ${_customer!['uuid']}',
                      style: Theme.of(context).textTheme.bodySmall),
                if (_customer != null && widget.customer == null)
                  CustomerInsights(
                      key: ValueKey(_customer!['uuid']),
                      customerId: _customer!['uuid'].toString()),
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Όνομα'),
                    validator: _required),
                TextFormField(
                    controller: _surname,
                    decoration: const InputDecoration(labelText: 'Επώνυμο'),
                    validator: _required),
                TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Κινητό')),
                TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email (προαιρετικό)'),
                    validator: (value) =>
                        value!.trim().isNotEmpty && !value.contains('@')
                            ? 'Έλεγξε το email'
                            : null),
                TextField(
                    controller: _birthday,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Ημερομηνία γέννησης (προαιρετικό)',
                      suffixIcon: IconButton(
                          onPressed: () => setState(() => _birthday.clear()),
                          icon: const Icon(Icons.clear)),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(_birthday.text) ??
                              DateTime(1990),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now());
                      if (date != null) {
                        setState(() => _birthday.text =
                            DateFormat('yyyy-MM-dd').format(date));
                      }
                    }),
                TextField(
                    controller: _source,
                    decoration: const InputDecoration(
                        labelText: 'Πηγή πελάτη',
                        hintText: 'Instagram, Google, σύσταση…')),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Πρόσθετα στοιχεία'),
                  children: [
                    TextField(
                        controller: _address,
                        decoration:
                            const InputDecoration(labelText: 'Διεύθυνση')),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _afm,
                        decoration: const InputDecoration(labelText: 'ΑΦΜ')),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _amka,
                        decoration: const InputDecoration(
                            labelText: 'ΑΜΚΑ (όπου χρειάζεται)')),
                    const SizedBox(height: 16),
                  ],
                ),
                TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Νέα σημείωση')),
                ...((_customer?['client_description'] ?? const []) as List)
                    .reversed
                    .map((note) => Text(note.toString())),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Αποθήκευση…' : 'Αποθήκευση')),
                if (_customer != null && widget.customer == null)
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _setCustomer(null)),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Νέος πελάτης'),
                  ),
              ],
            )),
      )),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Υποχρεωτικό πεδίο' : null;
}
