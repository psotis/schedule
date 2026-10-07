import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../repositories/user_admin_repository.dart';

class UserAdminDashboard extends StatefulWidget {
  const UserAdminDashboard({super.key});

  @override
  State<UserAdminDashboard> createState() => _UserAdminDashboardState();
}

class _UserAdminDashboardState extends State<UserAdminDashboard> {
  late Future<Map<String, dynamic>> _overview;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _overview = context.read<UserAdminRepository>().getOverview();
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule administration'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(_refresh),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _overview,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load administration data'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_refresh),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final overview = snapshot.data ?? const <String, dynamic>{};
          final totals = Map<String, dynamic>.from(
            overview['totals'] as Map? ?? const <String, dynamic>{},
          );
          final accounts = List<dynamic>.from(
            overview['accounts'] as List? ?? const <dynamic>[],
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(_refresh);
              await _overview;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: totals.entries
                      .map(
                        (entry) => SizedBox(
                          width: 180,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.replaceAll('_', ' '),
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.value.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text('Accounts', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...accounts.map((item) {
                  final account = Map<String, dynamic>.from(item as Map);
                  final memberships = List<dynamic>.from(
                    account['storeMemberships'] as List? ?? const <dynamic>[],
                  );
                  final storeNames = memberships.map((item) {
                    final membership = Map<String, dynamic>.from(item as Map);
                    final store = membership['store'] as Map?;
                    return store?['name']?.toString() ?? '';
                  }).where((name) => name.isNotEmpty);

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(account['email']?.toString() ?? ''),
                      subtitle: Text(
                        storeNames.isEmpty
                            ? 'No active stores'
                            : storeNames.join(', '),
                      ),
                      trailing: Text(account['role']?.toString() ?? ''),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
