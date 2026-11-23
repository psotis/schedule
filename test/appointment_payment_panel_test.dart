import 'package:scheldule/screens/calendar/widgets/customer_side.dart';
import 'package:scheldule/screens/calendar/widgets/customer_side_mobile.dart';
import 'package:scheldule/repositories/search_edit_user_repository.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/providers/search%20user/search_user_provider.dart';
import 'package:scheldule/utils/custom_text_form.dart';

import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_payment_panel.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

class _EventsApi extends ApiClient {
  final events = StreamController<void>.broadcast();
  _EventsApi({required super.client})
    : super(baseUrl: 'http://localhost/api/v1');
  @override
  Stream<void> watch(String resource) => events.stream;
}

void main() {
  Map<String, dynamic> booking() => {
    'uuid': 'booking',
    'client_record': {
      'uuid': 'client',
      'first_name': 'Test',
      'last_name': 'Customer',
    },
    'start_time': '2026-11-23T08:00:00Z',
    'end_time': '2026-11-23T09:00:00Z',
    'total_price': 30,
    'status': 'confirmed',
    'payments': [
      {
        'id': 'old-payment',
        'amount': 5.50,
        'method': 'cash',
        'paid_at': '2026-11-23T08:00:00Z',
      },
    ],
  };
  Finder statusField() => find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == 'Κατάσταση ραντεβού',
  );
  Finder methodField() => find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == 'Τρόπος νέας πληρωμής',
  );
  Future<void> mount(
    WidgetTester tester,
    _EventsApi api,
    Map<String, dynamic> data, {
    double width = 560,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider(
        create: (_) => AppointmentRepository(apiClient: api),
        child: MaterialApp(
          theme: buildAppTheme(brightness),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppointmentPaymentPanel(
                  appointment: AppointMent.fromJson(data),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await api.events.close();
    });
  }

  for (final width in [360.0, 560.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'inline card payment and completion fit at $width in $brightness',
        (tester) async {
          final data = booking();
          final writes = <Map<String, dynamic>>[];
          final api = _EventsApi(
            client: MockClient((request) async {
              if (request.method == 'POST') {
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                writes.add(body);
                data['payments'] = [
                  ...data['payments'] as List,
                  {
                    'id': 'new-payment',
                    'amount': body['amount'],
                    'method': body['method'],
                    'paid_at': '2026-11-23T09:00:00Z',
                  },
                ];
                if (body['complete'] == true) data['status'] = 'completed';
                return http.Response(jsonEncode({'data': {}}), 201);
              }
              return http.Response(
                jsonEncode({
                  'data': [data],
                }),
                200,
              );
            }),
          );
          await mount(tester, api, data, width: width, brightness: brightness);
          expect(find.text('Μετρητά: 5.50 €'), findsOneWidget);
          await tester.enterText(find.byType(TextField), '24,50');
          await tester.tap(methodField());
          await tester.pumpAndSettle();
          await tester.tap(find.text('Κάρτα').last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Πληρωμή & ολοκλήρωση'));
          await tester.tap(find.text('Πληρωμή & ολοκλήρωση'));
          await tester.pumpAndSettle();
          expect(writes, [
            {'amount': 24.5, 'method': 'card', 'complete': true},
          ]);
          expect(find.text('Πληρωμένα: 30.00 €'), findsOneWidget);
          expect(find.text('Κάρτα: 24.50 €'), findsOneWidget);
          expect(find.text('Υπόλοιπο: 0.00 €'), findsOneWidget);
          expect(find.text('Ολοκληρωμένο'), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('status saves directly without recording a payment', (
    tester,
  ) async {
    final data = booking();
    final writes = <Map<String, dynamic>>[];
    final api = _EventsApi(
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          writes.add(body);
          data['status'] = body['status'];
          return http.Response(jsonEncode({'data': data}), 200);
        }
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'data': [data],
          }),
          200,
        );
      }),
    );
    await mount(tester, api, data);
    await tester.tap(statusField());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ολοκληρωμένο').last);
    await tester.pumpAndSettle();
    expect(writes, [
      {'status': 'completed'},
    ]);
    expect(find.text('Ολοκληρωμένο'), findsOneWidget);
    expect(find.text('Πληρωμένα: 5.50 €'), findsOneWidget);
  });

  testWidgets('failed status save restores the current selection', (
    tester,
  ) async {
    final data = booking();
    final api = _EventsApi(
      client: MockClient(
        (request) async => request.method == 'PUT'
            ? http.Response(
                jsonEncode({'message': 'Cannot change status'}),
                409,
              )
            : http.Response(
                jsonEncode({
                  'data': [data],
                }),
                200,
              ),
      ),
    );
    await mount(tester, api, data);
    await tester.tap(statusField());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Σε εξέλιξη').last);
    await tester.pumpAndSettle();
    expect(find.text('Επιβεβαιωμένο'), findsOneWidget);
    expect(find.text('Cannot change status'), findsOneWidget);
  });

  testWidgets('realtime changes refresh payment amounts and methods', (
    tester,
  ) async {
    final data = booking();
    final api = _EventsApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': [data],
          }),
          200,
        ),
      ),
    );
    await mount(tester, api, data);
    (data['payments'] as List).add({
      'id': 'other-device',
      'amount': 4.5,
      'method': 'card',
      'paid_at': '2026-11-23T08:30:00Z',
    });
    api.events.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Πληρωμένα: 10.00 €'), findsOneWidget);
    expect(find.text('Κάρτα: 4.50 €'), findsOneWidget);
  });

  testWidgets('failed payment preserves amount for correction and retry', (
    tester,
  ) async {
    final data = booking();
    final api = _EventsApi(
      client: MockClient(
        (request) async => request.method == 'POST'
            ? http.Response(jsonEncode({'message': 'Payment rejected'}), 400)
            : http.Response(
                jsonEncode({
                  'data': [data],
                }),
                200,
              ),
      ),
    );
    await mount(tester, api, data);
    await tester.enterText(find.byType(TextField), '12.50');
    await tester.tap(find.text('Καταχώρηση πληρωμής'));
    await tester.pumpAndSettle();
    expect(find.text('Payment rejected'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '12.50',
    );
    expect(find.text('Πληρωμένα: 5.50 €'), findsOneWidget);
  });

  testWidgets('committed payment cannot be retried when refreshing fails', (
    tester,
  ) async {
    final data = booking();
    var committed = false;
    var writes = 0;
    final api = _EventsApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          committed = true;
          writes++;
          return http.Response(jsonEncode({'data': {}}), 201);
        }
        return committed
            ? http.Response(jsonEncode({'message': 'offline'}), 503)
            : http.Response(
                jsonEncode({
                  'data': [data],
                }),
                200,
              );
      }),
    );
    await mount(tester, api, data);
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Καταχώρηση πληρωμής'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Καταχώρηση πληρωμής'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Ανανέωση στοιχείων'), findsOneWidget);
  });
  testWidgets(
    'payment stays busy until server confirmation and rejects duplicate clicks',
    (tester) async {
      final data = booking();
      final completion = Completer<http.Response>();
      var writes = 0;
      final api = _EventsApi(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            writes++;
            return completion.future;
          }
          return http.Response(
            jsonEncode({
              'data': [data],
            }),
            200,
          );
        }),
      );
      await mount(tester, api, data);
      await tester.enterText(find.byType(TextField), '10');
      final button = find.widgetWithText(OutlinedButton, 'Καταχώρηση πληρωμής');
      await tester.tap(button);
      await tester.pump();
      expect(writes, 1);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      completion.complete(http.Response(jsonEncode({'data': {}}), 201));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('invalid payment amount never reaches the service', (
    tester,
  ) async {
    final data = booking();
    final api = _EventsApi(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'data': [data],
          }),
          200,
        );
      }),
    );
    await mount(tester, api, data);
    for (final value in ['', '0', '-5', 'NaN', 'Infinity']) {
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text('Καταχώρηση πληρωμής'));
      await tester.pumpAndSettle();
      expect(find.text('Συμπληρώστε ποσό μεγαλύτερο από 0.'), findsOneWidget);
    }
  });
  for (final mobile in [false, true]) {
    testWidgets(
      'complete ${mobile ? 'mobile' : 'desktop'} side panel retains every existing detail beside inline controls',
      (tester) async {
        tester.view.physicalSize = Size(mobile ? 360 : 560, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = booking();
        final client = {
          'uuid': 'client',
          'first_name': 'Test',
          'last_name': 'Customer',
          'phone': '6900000000',
          'amka': '12345678901',
          'owes': 12,
          'client_description': ['Existing customer note'],
        };
        data['client_record'] = client;
        data['employee'] = 'Demo Employee';
        data['position_description'] = 'Room 2';
        final api = _EventsApi(
          client: MockClient((request) async {
            Object response = [data];
            if (request.url.path.endsWith('/employee')) {
              response = [
                {
                  'uuid': 'employee',
                  'first_name': 'Demo',
                  'last_name': 'Employee',
                },
              ];
            } else if (request.url.path.endsWith('/client')) {
              response = [client];
            } else if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              data['payments'] = [
                ...data['payments'] as List,
                {
                  'id': 'new-payment',
                  'amount': body['amount'],
                  'method': body['method'],
                  'paid_at': '2026-11-23T09:00:00Z',
                },
              ];
              response = {};
            }
            return http.Response(jsonEncode({'data': response}), 200);
          }),
        );
        final searchRepository = SearchEditUserRepository(apiClient: api);
        final search = SearchUserProvider(
          searchEditUserRepository: searchRepository,
        );
        final appointment = AppointMent.fromJson(data);
        final customer = AppointMent.fromJson(client);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider(create: (_) => AppointmentRepository(apiClient: api)),
              Provider.value(value: searchRepository),
              Provider(create: (_) => AddAppointmentRepository(apiClient: api)),
              ChangeNotifierProvider.value(value: search),
            ],
            child: MaterialApp(
              theme: buildAppTheme(Brightness.dark),
              home: Scaffold(
                body: mobile
                    ? CustomerSideMobile(
                        customer: customer,
                        appointMent: appointment,
                      )
                    : CustomerSide(
                        customer: customer,
                        appointMent: appointment,
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder originalField(String label) => find.byWidgetPredicate(
          (widget) => widget is CustomTextForm && widget.labelText == label,
        );
        for (final label in [
          'Όνομα',
          'Επώνυμο',
          'ΑΜΚΑ',
          'Τηλέφωνο',
          'Σταθμός / χώρος',
          'Υπάλληλος',
          'Οφειλή',
          'Ραντεβού',
          'Πληρωμή',
          'Περιγραφή',
        ]) {
          expect(originalField(label), findsOneWidget, reason: label);
        }
        expect(find.text('Υπηρεσίες / εργαζόμενοι'), findsOneWidget);
        expect(find.text('Ολοκλήρωση / πληρωμή'), findsOneWidget);
        expect(find.text('Αλλαγή ημερομηνίας / ώρας'), findsOneWidget);
        expect(find.text('Αποθήκευση'), findsOneWidget);
        expect(find.text('Διαγραφή πελάτη'), findsOneWidget);
        expect(find.text('Existing customer note'), findsOneWidget);
        expect(find.byType(AppointmentPaymentPanel), findsOneWidget);
        expect(
          tester.widget<CustomTextForm>(originalField('Πληρωμή')).initial,
          '5.50',
        );
        final inlineAmount = find.descendant(
          of: find.byType(AppointmentPaymentPanel),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(inlineAmount);
        await tester.enterText(inlineAmount, '4.50');
        await tester.ensureVisible(find.text('Καταχώρηση πληρωμής'));
        await tester.tap(find.text('Καταχώρηση πληρωμής'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<CustomTextForm>(originalField('Πληρωμή')).initial,
          '10.00',
        );
        expect(find.text('Πληρωμένα: 10.00 €'), findsOneWidget);
        expect(
          tester.widget<CustomTextForm>(originalField('ΑΜΚΑ')).initial,
          '12345678901',
        );
        expect(
          tester
              .widget<CustomTextForm>(originalField('Σταθμός / χώρος'))
              .initial,
          'Room 2',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        search.dispose();
        await api.events.close();
      },
    );
  }
}
