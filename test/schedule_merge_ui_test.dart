import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/keys/material_key.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/screens/responsive_ui/settings/employee_schedule_dialog.dart';
import 'package:scheldule/screens/responsive_ui/customer/customer_merge_dialog.dart';
import 'package:scheldule/screens/responsive_ui/customer/customer_merge_notice_listener.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

http.Response response(Object data) => http.Response(
  jsonEncode({'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
void main() {
  for (final width in [360.0, 768.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'independent split shifts and date overrides save at $width in $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final employee = Employee.fromJson({
            'uuid': 'employee',
            'first_name': 'Νικολέτα',
            'weekly_schedule_enabled': true,
            'availability': [
              {'weekday': 1, 'start_time': '09:00:00', 'end_time': '12:00:00'},
              {'weekday': 1, 'start_time': '13:00:00', 'end_time': '17:00:00'},
              {'weekday': 2, 'start_time': '17:00:00', 'end_time': '21:00:00'},
            ],
            'scheduleExceptions': [
              {
                'date': '2026-11-30',
                'intervals': [
                  {'start_time': '18:00', 'end_time': '21:00'},
                ],
                'note': 'Κυλιόμενο',
              },
            ],
          });
          Map<String, dynamic>? result;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (_) =>
                            EmployeeScheduleDialog(employee: employee),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final monday = find
              .ancestor(of: find.text('Δευτέρα'), matching: find.byType(Card))
              .first;
          final start = find
              .descendant(of: monday, matching: field('Από (HH:mm)'))
              .first;
          await tester.ensureVisible(start);
          await tester.enterText(start, '9');
          await tester.tap(find.widgetWithText(FilledButton, 'Αποθήκευση'));
          await tester.pumpAndSettle();
          expect(result, isNull);
          expect(
            find.text('Έλεγξε τις ώρες. Χρησιμοποίησε μορφή 09:00.'),
            findsOneWidget,
          );
          await tester.ensureVisible(start);
          await tester.enterText(start, '08:30');
          await tester.tap(find.widgetWithText(FilledButton, 'Αποθήκευση'));
          await tester.pumpAndSettle();
          expect(result!['availability'], [
            {'weekday': 1, 'start_time': '08:30', 'end_time': '12:00'},
            {'weekday': 1, 'start_time': '13:00', 'end_time': '17:00'},
            {'weekday': 2, 'start_time': '17:00', 'end_time': '21:00'},
          ]);
          expect(result!['schedule_exceptions'], [
            {
              'date': '2026-11-30',
              'intervals': [
                {'start_time': '18:00', 'end_time': '21:00'},
              ],
              'note': 'Κυλιόμενο',
            },
          ]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
      testWidgets(
        'customer merge requires preview and identity confirmation at $width in $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final source = {
            'uuid': 'source',
            'first_name': 'Άννα',
            'last_name': 'Παπαδοπούλου',
            'phone': '',
          };
          final target = {
            'uuid': 'target',
            'first_name': 'Αννα',
            'last_name': 'Παπαδοπουλου',
            'phone': '6912345678',
          };
          final writes = <Map<String, dynamic>>[];
          final api = ApiClient(
            baseUrl: 'http://localhost/api/v1',
            client: MockClient((request) async {
              if (request.method == 'POST') {
                writes.add(Map<String, dynamic>.from(jsonDecode(request.body)));
                return response({'target_uuid': 'target'});
              }
              if (request.url.path.endsWith('/merge-preview')) {
                return response({
                  'source': {'name': 'Άννα Παπαδοπούλου', 'appointments': 1},
                  'target': {'name': 'Αννα Παπαδοπουλου', 'appointments': 2},
                  'conflicts': [],
                  'preview_token': 'snapshot-token',
                });
              }
              return response([source, target]);
            }),
          );
          String? result;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      result = await showDialog<String>(
                        context: context,
                        builder: (_) =>
                            CustomerMergeDialog(source: source, apiClient: api),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Αννα Παπαδοπουλου'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Προεπισκόπηση'));
          await tester.pumpAndSettle();
          expect(writes, isEmpty);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Συγχώνευση'),
                )
                .onPressed,
            isNull,
          );
          final checkbox = find.byType(Checkbox);
          await tester.ensureVisible(checkbox);
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Συγχώνευση'));
          await tester.pumpAndSettle();
          expect(result, 'target');
          expect(writes, [
            {
              'target_id': 'target',
              'preview_token': 'snapshot-token',
              'confirm_same_customer': true,
            },
          ]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'ordinary creation is silent and only a real merge produces its reason notice',
    (tester) async {
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient(
          (request) async => response(
            request.url.path.endsWith('/normal')
                ? {'uuid': 'new'}
                : {
                    'uuid': 'target',
                    'merge_notice': {
                      'source_name': 'Άννα 2',
                      'target_name': 'Άννα',
                      'reason': 'mobile',
                      'source_uuid': 'source',
                      'target_uuid': 'target',
                    },
                  },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: AppMaterialKey.scaffoldMessengerKey,
          builder: (context, child) =>
              CustomerMergeNoticeListener(apiClient: api, child: child!),
          home: Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    await api.post('/normal');
                  },
                  child: const Text('New customer'),
                ),
                TextButton(
                  onPressed: () async {
                    await api.post('/duplicate');
                  },
                  child: const Text('Duplicate'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('New customer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('συγχωνεύτηκε'), findsNothing);
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(find.textContaining('συγχωνεύτηκε'), findsOneWidget);
      expect(find.textContaining('ίδιο κινητό'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
