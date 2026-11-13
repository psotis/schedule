import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../repositories/user_admin_repository.dart';

Map<String, dynamic> _map(dynamic value) =>
    Map<String, dynamic>.from(value as Map? ?? {});
List<Map<String, dynamic>> _rows(dynamic value) =>
    (value as List? ?? []).map(_map).toList();
String _time(dynamic value) {
  final date = DateTime.tryParse('$value');
  return date == null
      ? 'Δεν έχει καταγραφεί'
      : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
}

const _actions = {
  'suspend': 'Αναστολή πρόσβασης',
  'activate': 'Ενεργοποίηση',
  'archive': 'Διαγραφή (αρχειοθέτηση)',
  'restore': 'Επαναφορά',
  'reset-password': 'Νέος κωδικός πρόσβασης',
  'block': 'Αποκλεισμός email',
  'unblock': 'Άρση αποκλεισμού'
};
String _role(dynamic value) =>
    const {
      'owner': 'Ιδιοκτήτης',
      'admin': 'Διαχειριστής',
      'staff': 'Εργαζόμενος',
      'user-admin': 'Διαχειριστής πλατφόρμας'
    }[value] ??
    '$value';

class UserAdminDashboard extends StatefulWidget {
  const UserAdminDashboard({super.key});
  @override
  State<UserAdminDashboard> createState() => _UserAdminDashboardState();
}

class _UserAdminDashboardState extends State<UserAdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Map<String, dynamic>> _overview;
  final _search = TextEditingController();
  int _year = DateTime.now().year, _month = 0, _page = 1;
  bool _busy = false;
  UserAdminRepository get repository => context.read<UserAdminRepository>();
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    _overview = repository.getOverview(
        year: _year, month: _month, page: _page, search: _search.text.trim());
  }

  void _reload() => setState(_refresh);

  Future<void> _execute(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Η ενέργεια ολοκληρώθηκε.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(
      String label, String target, Future<void> Function() operation,
      {bool archive = false}) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(label),
              content: Text(
                  '$target\n\n${archive ? 'Η πρόσβαση θα απενεργοποιηθεί. Οι καρτέλες, οι πληρωμές και τα ραντεβού διατηρούνται και η ενέργεια μπορεί να αναιρεθεί.' : 'Θέλετε να συνεχίσετε; Οι τρέχουσες συνεδρίες μπορεί να αποσυνδεθούν.'}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Ακύρωση')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Επιβεβαίωση'))
              ],
            ));
    if (confirmed == true && mounted) await _execute(operation);
  }

  Future<void> _password(Map<String, dynamic> user) async {
    var enteredPassword = '';
    final form = GlobalKey<FormState>();
    final password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Νέος κωδικός Rantevia'),
              content: Form(
                  key: form,
                  child: SizedBox(
                      width: 380,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${user['email']}'),
                            const SizedBox(height: 14),
                            const Text(
                                'Οι υπάρχουσες συνεδρίες θα ανακληθούν. Ο κωδικός Google δεν αλλάζει.'),
                            const SizedBox(height: 18),
                            TextFormField(
                                onChanged: (value) => enteredPassword = value,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Νέος κωδικός (12+ χαρακτήρες)'),
                                validator: (value) => (value ?? '').length < 12
                                    ? 'Τουλάχιστον 12 χαρακτήρες'
                                    : null),
                          ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ακύρωση')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(context, enteredPassword);
                      }
                    },
                    child: const Text('Αλλαγή κωδικού'))
              ],
            ));
    if (password != null && mounted) {
      await _execute(() => repository
          .manageUser('${user['uuid']}', 'reset-password', password: password));
    }
  }

  Future<void> _blockDialog() async {
    var enteredEmail = '', enteredReason = '';
    final value = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Αποκλεισμός email'),
              content: SizedBox(
                  width: 400,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Αποκλείει την εγγραφή και τη σύνδεση, συμπεριλαμβανομένου του Google login.'),
                    const SizedBox(height: 18),
                    TextField(
                        onChanged: (value) => enteredEmail = value,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 18),
                    TextField(
                        onChanged: (value) => enteredReason = value,
                        maxLength: 500,
                        decoration: const InputDecoration(
                            labelText: 'Αιτιολογία (προαιρετική)')),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ακύρωση')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, {
                          'email': enteredEmail.trim(),
                          'reason': enteredReason.trim()
                        }),
                    child: const Text('Αποκλεισμός'))
              ],
            ));
    if (value != null && mounted) {
      await _execute(() =>
          repository.blockEmail(value['email']!, reason: value['reason']!));
    }
  }

  Widget _user(Map<String, dynamic> user, Map<String, dynamic> data,
      {String? storeRole, bool membershipActive = true}) {
    final online =
        _map(_map(data['presence'])['users']).containsKey('${user['uuid']}');
    final usage =
        _rows(data['usage']).where((row) => row['user_uuid'] == user['uuid']);
    final stats = usage.isEmpty ? <String, dynamic>{} : usage.first;
    final status = user['email_blocked'] == true
        ? 'Email αποκλεισμένο'
        : user['is_deleted'] == true
            ? 'Αρχειοθετημένος'
            : user['is_active'] == false
                ? 'Σε αναστολή'
                : 'Ενεργός';
    final memberships = _rows(user['storeMemberships']);
    return Card(
        child: ExpansionTile(
      title: Text('${user['email']}', overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${_role(storeRole ?? user['role'])} · $status${online ? ' · Συνδεδεμένος τώρα' : ''}${membershipActive ? '' : ' · Ανενεργή συμμετοχή'}'),
      leading: Icon(online ? Icons.wifi_rounded : Icons.person_outline_rounded,
          color: online ? Theme.of(context).colorScheme.primary : null),
      trailing: user['role'] == 'user-admin'
          ? null
          : PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (action) {
                if (action == 'reset-password') {
                  _password(user);
                  return;
                }
                _confirm(
                    _actions[action]!,
                    '${user['email']}',
                    () => action == 'block'
                        ? repository.blockEmail('${user['email']}')
                        : repository.manageUser('${user['uuid']}', action),
                    archive: action == 'archive');
              },
              itemBuilder: (_) => [
                    for (final action in [
                      'reset-password',
                      user['is_active'] == false ? 'activate' : 'suspend',
                      user['is_deleted'] == true ? 'restore' : 'archive',
                      'block'
                    ])
                      PopupMenuItem(
                          value: action, child: Text(_actions[action]!))
                  ]),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                [
                  'Όνομα: ${user['display_name'] ?? ''}',
                  'Εγγραφή: ${_time(user['created_at'])}',
                  'Τελευταία σύνδεση: ${_time(user['last_login_at'])}',
                  'Τελευταία δραστηριότητα: ${_time(user['last_seen_at'])}',
                  'Στην επιλεγμένη περίοδο: ${stats['active_days'] ?? 0} ενεργές ημέρες · ${stats['logins'] ?? 0} συνδέσεις · ${stats['requests'] ?? 0} αιτήματα',
                  ...memberships.map((member) =>
                      '${_map(member['store'])['name']} · ${_role(member['role'])} · ${_map(_map(member['store'])['storeType'])['name'] ?? ''}'),
                ].join('\n'),
                style: const TextStyle(height: 1.8)))
      ],
    ));
  }

  Widget _store(Map<String, dynamic> store, Map<String, dynamic> data) {
    final count = _map(_map(data['presence'])['stores'])['${store['id']}'] ?? 0;
    return Card(
        child: ExpansionTile(
      title: Text('${store['name']}'),
      subtitle: Text(
          '${_map(store['storeType'])['name']} · ${store['is_archived'] == true ? 'Αρχειοθετημένο' : store['is_active'] == true ? 'Ενεργό' : 'Σε αναστολή'} · $count συνδεδεμένες συνεδρίες'),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Εγγραφή: ${_time(store['created_at'])}\n${store['email']} · ${store['phone']}\n${store['address']}',
                style: const TextStyle(height: 1.8))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _StoreRecords(
                      id: '${store['id']}',
                      name: '${store['name']}',
                      repository: repository)),
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Δεδομένα καταστήματος')),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _confirm(
                      'Αλλαγή πρόσβασης',
                      '${store['name']}',
                      () => repository.manageStore('${store['id']}',
                          store['is_active'] == true ? 'suspend' : 'activate')),
              child: Text(
                  store['is_active'] == true ? 'Αναστολή' : 'Ενεργοποίηση')),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _confirm(
                      store['is_archived'] == true
                          ? 'Επαναφορά'
                          : 'Αρχειοθέτηση',
                      '${store['name']}',
                      () => repository.manageStore('${store['id']}',
                          store['is_archived'] == true ? 'restore' : 'archive'),
                      archive: true),
              child: Text(store['is_archived'] == true
                  ? 'Επαναφορά'
                  : 'Διαγραφή (αρχειοθέτηση)')),
        ]),
        const SizedBox(height: 16),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Λογαριασμοί ιδιοκτητών και ομάδας',
                style: TextStyle(fontWeight: FontWeight.w700))),
        for (final member in _rows(store['memberships']))
          _user(_map(member['user']), data,
              storeRole: '${member['role']}',
              membershipActive: member['is_active'] != false),
      ],
    ));
  }

  Widget _statistics(Map<String, dynamic> data) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Εγγραφές περιόδου: ${_map(data['period'])['signups']}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
            'Καταγραφή χρήσης από: ${_map(data['tracking'])['first_recorded_day'] ?? 'Δεν υπάρχουν ακόμη δεδομένα'}. Οι συνδέσεις και τα αιτήματα δεν αποτελούν μέτρηση χρόνου παραμονής.'),
        const SizedBox(height: 18),
        Text(
            'Συνολικά ενεργοί χρήστες με καταγεγραμμένη χρήση: ${_map(data['tracking'])['active_users'] ?? 0} · Συνδεδεμένοι τώρα: ${_map(_map(data['presence'])['users']).length}'),
        const SizedBox(height: 18),
        const Text('Εγγραφές χρηστών ανά μήνα',
            style: TextStyle(fontWeight: FontWeight.w700)),
        for (final row in _rows(data['registrations']))
          ListTile(
              title: Text('${row['period']}'),
              trailing: Text('${row['count']} χρήστες')),
        const SizedBox(height: 12),
        const Text('Νέα καταστήματα ανά μήνα',
            style: TextStyle(fontWeight: FontWeight.w700)),
        for (final row in _rows(data['store_registrations']))
          ListTile(
              title: Text('${row['period']}'),
              trailing: Text('${row['count']} καταστήματα')),
        const SizedBox(height: 12),
        const Text('Χρήση πλατφόρμας ανά μήνα',
            style: TextStyle(fontWeight: FontWeight.w700)),
        for (final row in _rows(data['activity']))
          Card(
              child: ListTile(
                  title: Text('${row['period']}'),
                  subtitle: Text(
                      '${row['active_users']} ενεργοί χρήστες · ${row['active_stores']} καταστήματα\n${row['logins']} συνδέσεις · ${row['requests']} αιτήματα'))),
        if (_rows(data['activity']).isEmpty)
          const Padding(
              padding: EdgeInsets.all(20),
              child:
                  Text('Δεν έχει καταγραφεί χρήση στην επιλεγμένη περίοδο.')),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Rantevia · Διαχείριση πλατφόρμας'),
            actions: [
              IconButton(
                  tooltip: 'Ανανέωση',
                  onPressed: _busy ? null : _reload,
                  icon: const Icon(Icons.refresh_rounded)),
              IconButton(
                  tooltip: 'Αποσύνδεση',
                  onPressed: () async {
                    await context.read<AuthProvider>().signout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded)),
            ]),
        body: FutureBuilder<Map<String, dynamic>>(
            future: _overview,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: FilledButton(
                        onPressed: _reload,
                        child: const Text('Αποτυχία φόρτωσης · Δοκιμή ξανά')));
              }
              final data = snapshot.data ?? {};
              return Column(children: [
                if (_busy) const LinearProgressIndicator(),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                              width: 260,
                              child: TextField(
                                  controller: _search,
                                  decoration: const InputDecoration(
                                      labelText: 'Αναζήτηση email / ονόματος',
                                      prefixIcon: Icon(Icons.search)),
                                  onSubmitted: (_) {
                                    _page = 1;
                                    _reload();
                                  })),
                          IconButton(
                              tooltip: 'Αναζήτηση',
                              onPressed: () {
                                _page = 1;
                                _reload();
                              },
                              icon: const Icon(Icons.search)),
                          SizedBox(
                              width: 130,
                              child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _year,
                                  decoration:
                                      const InputDecoration(labelText: 'Έτος'),
                                  items: [
                                    for (var year = DateTime.now().year;
                                        year >= 2020;
                                        year--)
                                      DropdownMenuItem(
                                          value: year, child: Text('$year'))
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _year = value;
                                      _reload();
                                    }
                                  })),
                          SizedBox(
                              width: 170,
                              child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _month,
                                  decoration: const InputDecoration(
                                      labelText: 'Περίοδος'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: 0, child: Text('Όλο το έτος')),
                                    for (var month = 1; month <= 12; month++)
                                      DropdownMenuItem(
                                          value: month,
                                          child: Text('Μήνας $month'))
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _month = value;
                                      _reload();
                                    }
                                  })),
                        ])),
                TabBar(controller: _tabs, isScrollable: true, tabs: [
                  Tab(text: 'Καταστήματα'),
                  Tab(text: 'Λογαριασμοί'),
                  Tab(text: 'Στατιστικά'),
                  Tab(text: 'Αποκλεισμοί'),
                  Tab(text: 'Ιστορικό ενεργειών')
                ]),
                Expanded(
                    child: TabBarView(
                        controller: _tabs,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                      _pageList([
                        for (final store in _rows(data['stores']))
                          _store(store, data)
                      ], data['store_count'] as int? ?? 0),
                      _pageList([
                        for (final user in _rows(data['accounts']))
                          _user(user, data)
                      ], data['account_count'] as int? ?? 0),
                      ListView(padding: const EdgeInsets.all(20), children: [
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          for (final entry in _map(data['totals']).entries)
                            SizedBox(
                                width: 170,
                                child: Card(
                                    child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('${entry.key} · συνολικά'),
                                              const SizedBox(height: 8),
                                              Text('${entry.value}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall)
                                            ]))))
                        ]),
                        const SizedBox(height: 24),
                        _statistics(data),
                      ]),
                      _pageList([
                        Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                                onPressed: _busy ? null : _blockDialog,
                                icon: const Icon(Icons.block),
                                label: const Text('Αποκλεισμός email'))),
                        for (final email in _rows(data['blocked_emails']))
                          Card(
                              child: ListTile(
                                  title: Text('${email['email']}'),
                                  subtitle: Text(
                                      '${email['reason']}\n${_time(email['created_at'])}'),
                                  trailing: IconButton(
                                      tooltip: 'Άρση αποκλεισμού',
                                      onPressed: _busy
                                          ? null
                                          : () => _confirm(
                                              'Άρση αποκλεισμού',
                                              '${email['email']}',
                                              () => repository.blockEmail(
                                                  '${email['email']}',
                                                  block: false)),
                                      icon: const Icon(
                                          Icons.lock_open_rounded)))),
                      ], data['blocked_count'] as int? ?? 0),
                      _pageList([
                        for (final event in _rows(data['audit']))
                          Card(
                              child: ListTile(
                                  title: Text(
                                      '${_actions[event['action']] ?? event['action']} · ${event['target_type']}'),
                                  subtitle: Text(
                                      '${event['target_id']}\n${_time(event['created_at'])}\nΔιαχειριστής: ${event['actor_uuid']}')))
                      ], null),
                    ])),
              ]);
            }),
      );

  Widget _pageList(List<Widget> children, int? total) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        ...children,
        if (children.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Δεν υπάρχουν αποτελέσματα.')),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'Προηγούμενη σελίδα',
              onPressed: _page <= 1
                  ? null
                  : () {
                      _page--;
                      _reload();
                    },
              icon: const Icon(Icons.chevron_left)),
          Flexible(
              child: Text(
                  'Σελίδα $_page${total == null ? '' : ' · $total εγγραφές'}',
                  textAlign: TextAlign.center)),
          IconButton(
              tooltip: 'Επόμενη σελίδα',
              onPressed: total != null && _page * 30 >= total ||
                      total == null && children.length < 30
                  ? null
                  : () {
                      _page++;
                      _reload();
                    },
              icon: const Icon(Icons.chevron_right)),
        ]),
      ]);
}

class _StoreRecords extends StatefulWidget {
  final String id, name;
  final UserAdminRepository repository;
  const _StoreRecords(
      {required this.id, required this.name, required this.repository});
  @override
  State<_StoreRecords> createState() => _StoreRecordsState();
}

class _StoreRecordsState extends State<_StoreRecords> {
  String section = 'clients';
  int page = 1;
  late Future<Map<String, dynamic>> records;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    records = widget.repository.records(widget.id, section, page);
  }

  @override
  Widget build(BuildContext context) => Dialog(
      child: SizedBox(
          width: 880,
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: Text(widget.name,
                          style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                      tooltip: 'Κλείσιμο',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    initialValue: section,
                    decoration: const InputDecoration(
                        labelText: 'Δεδομένα καταστήματος'),
                    items: const [
                      DropdownMenuItem(
                          value: 'clients', child: Text('Πελάτες')),
                      DropdownMenuItem(
                          value: 'employees', child: Text('Εργαζόμενοι')),
                      DropdownMenuItem(
                          value: 'appointments', child: Text('Ραντεβού')),
                      DropdownMenuItem(
                          value: 'services', child: Text('Υπηρεσίες')),
                      DropdownMenuItem(
                          value: 'transactions',
                          child: Text('Οικονομικές κινήσεις'))
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          section = value;
                          page = 1;
                          load();
                        });
                      }
                    }),
                const SizedBox(height: 16),
                Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                        future: records,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: FilledButton(
                                    onPressed: () => setState(load),
                                    child: const Text('Δοκιμή ξανά')));
                          }
                          final data = snapshot.data ?? {};
                          final rows = _rows(data['rows']);
                          return Column(children: [
                            Expanded(
                                child: ListView(children: [
                              for (final row in rows)
                                Card(
                                    child: ExpansionTile(
                                  title: Text(
                                      '${row['name'] ?? row['first_name'] ?? row['service_name'] ?? row['start_time'] ?? row['occurred_at'] ?? row['uuid'] ?? row['id']} ${row['last_name'] ?? ''}'),
                                  childrenPadding: const EdgeInsets.all(14),
                                  children: [
                                    for (final entry in row.entries.where(
                                        (entry) =>
                                            entry.value != null &&
                                            '${entry.value}'.isNotEmpty &&
                                            entry.value is! Map &&
                                            entry.value is! List))
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: SelectableText(
                                                  '${entry.key.replaceAll('_', ' ')}: ${entry.value}')))
                                  ],
                                )),
                              if (rows.isEmpty)
                                const ListTile(
                                    title: Text('Δεν υπάρχουν εγγραφές.')),
                            ])),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                      onPressed: page <= 1
                                          ? null
                                          : () => setState(() {
                                                page--;
                                                load();
                                              }),
                                      icon: const Icon(Icons.chevron_left)),
                                  Text('Σελίδα $page'),
                                  IconButton(
                                      onPressed: page * 30 >=
                                              (data['count'] as int? ?? 0)
                                          ? null
                                          : () => setState(() {
                                                page++;
                                                load();
                                              }),
                                      icon: const Icon(Icons.chevron_right))
                                ])
                          ]);
                        })),
              ]))));
}
