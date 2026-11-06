import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/screens/responsive_ui/desktop/income-expenses/inc_exp_main.dart';
import 'package:scheldule/screens/responsive_ui/finance_access_gate.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

class _FinanceApi extends ApiClient {
  final changes = StreamController<void>.broadcast();
  _FinanceApi(http.Client client)
      : super(client: client, baseUrl: 'http://localhost/api/v1');
  @override
  Stream<void> watch(String resource) => changes.stream;
}

String money(double value) =>
    NumberFormat.currency(locale: 'el_GR', symbol: '€', decimalDigits: 2)
        .format(value);

void main() {
  final lookup = {
    'paymentMethods': [
      {'id': 'cash', 'label': 'Μετρητά'},
      {'id': 'card', 'label': 'Κάρτα'}
    ],
    'appointmentTypes': [
      {'id': 'grafeio', 'label': 'Στον χώρο'}
    ],
    'incomeCategories': [
      {'id': 'services', 'label': 'Έσοδα υπηρεσιών'}
    ],
    'expenseCategories': [
      {
        'id': 'operating',
        'label': 'Λειτουργικά έξοδα και συντήρηση επαγγελματικού χώρου'
      },
      {'id': 'staff', 'label': 'Προσωπικό'},
    ],
    'expenseSubcategories': {
      'operating': [
        {'id': 'rent', 'label': 'Ενοίκιο'}
      ],
      'staff': [
        {'id': 'salary', 'label': 'Μισθοδοσία'}
      ],
    },
  };
  for (final width in [360.0, 800.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('finance layout and totals at $width in $brightness',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final day = <Map<String, dynamic>>[
          {
            'id': 'income',
            'type': 'income',
            'amount': 120.25,
            'occurred_at': DateTime.now().toIso8601String(),
            'category': 'services',
            'description': 'Daily receipt'
          },
          {
            'id': 'expense',
            'type': 'expense',
            'amount': 20.10,
            'occurred_at': DateTime.now().toIso8601String(),
            'category': 'operating',
            'subcategory': 'rent',
            'description': 'Daily expense'
          },
        ];
        final posted = <Map<String, dynamic>>[];
        final deleted = <String>[];
        final api = _FinanceApi(MockClient((request) async {
          Object data = {};
          if (request.url.path.endsWith('/finance/settings')) {
            data = {'lookup': lookup};
          } else if (request.method == 'DELETE') {
            final id = request.url.pathSegments.last;
            deleted.add(id);
            day.removeWhere((entry) => entry['id'] == id);
          } else if (request.method == 'POST') {
            final value = jsonDecode(request.body) as Map<String, dynamic>;
            posted.add(value);
            day.add({...value, 'id': 'new-record'});
          } else if (request.url.path.endsWith('/transactions')) {
            final from = DateTime.parse(request.url.queryParameters['from']!);
            final to = DateTime.parse(request.url.queryParameters['to']!);
            data = to.difference(from).inHours < 48
                ? day
                : [
                    ...day,
                    {
                      'id': 'prior-income',
                      'type': 'income',
                      'amount': 1130.5,
                      'occurred_at': from.toIso8601String()
                    },
                    {
                      'id': 'prior-expense',
                      'type': 'expense',
                      'amount': 380.15,
                      'occurred_at': from.toIso8601String()
                    },
                  ];
          }
          return http.Response(jsonEncode({'data': data}), 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }));
        await tester.pumpWidget(MultiProvider(
            providers: [
              Provider<ApiClient>.value(value: api),
              Provider(create: (_) => TransactionRepository(apiClient: api)),
            ],
            child: MaterialApp(
                theme: buildAppTheme(brightness), home: const IncExpMain())));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(money(1250.75)), findsOneWidget);
        expect(find.text(money(400.25)), findsOneWidget);
        expect(find.text(money(850.50)), findsOneWidget);
        expect(find.text(money(100.15)), findsOneWidget);
        final incomeChip = find.widgetWithText(ChoiceChip, 'Έσοδα');
        expect(find.textContaining('Daily expense'), findsOneWidget);
        await tester.ensureVisible(incomeChip);
        await tester.pumpAndSettle();
        await tester.tap(incomeChip);
        await tester.pumpAndSettle();
        expect(find.textContaining('Daily expense'), findsNothing);
        expect(find.text(money(100.15)),
            findsOneWidget); // Filtering never changes totals.
        day[0]['amount'] = 121.25;
        api.changes.add(null);
        await tester.pumpAndSettle();
        expect(find.text(money(101.15)),
            findsOneWidget); // Server events refresh the day too.
        final amountField = find.widgetWithText(TextField, 'Ποσό');
        await tester.ensureVisible(amountField);
        await tester.pumpAndSettle();
        await tester.enterText(amountField, '42,35');
        final description =
            find.widgetWithText(TextField, 'Περιγραφή (προαιρετικό)');
        await tester.ensureVisible(description);
        await tester.pumpAndSettle();
        await tester.enterText(description, 'New expense');
        final save = find.widgetWithText(FilledButton, 'Αποθήκευση κίνησης');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(posted.single['amount'], 42.35);
        expect(posted.single['type'], 'expense');
        expect(posted.single['category'], 'operating');
        expect(posted.single['subcategory'], 'rent');
        expect(posted.single['description'], 'New expense');
        final allChip = find.widgetWithText(ChoiceChip, 'Όλες');
        await tester.ensureVisible(allChip);
        await tester.pumpAndSettle();
        await tester.tap(allChip);
        await tester.pumpAndSettle();
        final newRecord = find.byKey(const ValueKey('new-record'));
        await tester.ensureVisible(newRecord);
        await tester.pumpAndSettle();
        final deleteButton = find.descendant(
            of: newRecord, matching: find.byTooltip('Διαγραφή κίνησης'));
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
        expect(deleted, isEmpty);
        await tester.tap(find.text('Ακύρωση'));
        await tester.pumpAndSettle();
        expect(deleted, isEmpty);
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Διαγραφή'));
        await tester.pumpAndSettle();
        expect(deleted, ['new-record']);
        expect(find.textContaining('New expense'), findsNothing);

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await api.changes.close();
      });
    }
  }

  testWidgets(
      'finance PIN still verifies before opening the destination on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <http.Request>[];
    final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
              jsonEncode({
                'data': request.method == 'GET' ? {'has_pin': true} : {}
              }),
              200);
        }));
    await tester.pumpWidget(Provider(
        create: (_) => TransactionRepository(apiClient: api),
        child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
                body: FinanceAccessGate(
              destinationBuilder: (_) =>
                  const Scaffold(body: Text('Finance opened')),
            )))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final pin = find.byType(TextFormField);
    await tester.enterText(pin, '1234');
    await tester.ensureVisible(find.text('Είσοδος στα οικονομικά'));
    await tester.tap(find.text('Είσοδος στα οικονομικά'));
    await tester.pumpAndSettle();
    expect(find.text('Finance opened'), findsOneWidget);
    expect(requests.last.url.path, endsWith('/finance/access/verify'));
    expect(jsonDecode(requests.last.body), {'pin': '1234'});
  });
}
