import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/user_admin_repository.dart';
import 'package:scheldule/screens/user_admin/user_admin_dashboard.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 800.0, 1440.0]) {
    testWidgets(
        'platform admin actions fit at $width and preserve selected tab',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <Map<String, dynamic>>[];
      final owner = {
        'uuid': 'owner-id',
        'email': 'owner@example.test',
        'display_name': 'Owner',
        'role': 'admin',
        'is_active': true,
        'created_at': '2026-11-01T08:00:00Z'
      };
      final api = ApiClient(
          baseUrl: 'http://localhost/api',
          client: MockClient((request) async {
            if (request.method == 'PUT') {
              writes.add(jsonDecode(request.body) as Map<String, dynamic>);
              return http.Response('{"data":null}', 200);
            }
            return http.Response(
                jsonEncode({
                  'data': {
                    'totals': {'users': 2, 'stores': 1},
                    'accounts': [owner],
                    'account_count': 1,
                    'stores': [
                      {
                        'id': 'store-id',
                        'name': 'Test store',
                        'is_active': true,
                        'storeType': {'name': 'Nail Salon'},
                        'memberships': [
                          {'role': 'owner', 'user': owner}
                        ]
                      }
                    ],
                    'store_count': 1,
                    'blocked_count': 0,
                    'blocked_emails': [],
                    'audit': [],
                    'usage': [],
                    'registrations': [
                      {'period': '2026-11', 'count': 2}
                    ],
                    'activity': [],
                    'store_registrations': [],
                    'tracking': {},
                    'period': {'signups': 2},
                    'presence': {
                      'users': {'owner-id': 1},
                      'stores': {'store-id': 1}
                    },
                  }
                }),
                200);
          }));
      await tester.pumpWidget(Provider(
          create: (_) => UserAdminRepository(apiClient: api),
          child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: const UserAdminDashboard())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Test store'), findsOneWidget);
      expect(find.textContaining('Nail Salon'), findsOneWidget);
      final accounts = find.widgetWithText(Tab, 'Λογαριασμοί');
      await tester.ensureVisible(accounts);
      await tester.pumpAndSettle();
      await tester.tap(accounts);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byType(PopupMenuButton<String>).hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Αναστολή πρόσβασης'));
      await tester.pumpAndSettle();
      expect(find.textContaining('owner@example.test'), findsWidgets);
      await tester.tap(find.text('Επιβεβαίωση'));
      await tester.pumpAndSettle();
      expect(writes.single['action'], 'suspend');
      expect(
          find.byType(PopupMenuButton<String>).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester
          .tap(find.byType(PopupMenuButton<String>).hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Νέος κωδικός πρόσβασης'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).last, 'A-new-test-password');
      await tester.tap(find.text('Αλλαγή κωδικού'));
      await tester.pumpAndSettle();
      expect(writes.last,
          {'action': 'reset-password', 'password': 'A-new-test-password'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
