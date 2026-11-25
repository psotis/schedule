import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/providers/search%20user/search_user_provider.dart';
import 'package:scheldule/providers/store/store_provider.dart';
import 'package:scheldule/providers/toggle_screen/toggle_screen_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/search_edit_user_repository.dart';
import 'package:scheldule/repositories/store_repository.dart';
import 'package:scheldule/screens/responsive_ui/customer/customer_profile_form.dart';
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_card.dart'
    as desktop;
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_card.dart'
    as tablet;
import 'package:scheldule/screens/responsive_ui/mobile/customer/widgets/customer_card.dart'
    as mobile;
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:scheldule/utils/custom_text_form.dart';

class _SessionApi extends ApiClient {
  _SessionApi({required super.client})
    : super(baseUrl: 'http://localhost/api/v1');
  int revision = 0;
  final sessions = StreamController<int>.broadcast();
  @override
  int get sessionRevision => revision;
  @override
  Stream<int> get sessionChanges => sessions.stream;
}

void main() {
  for (final type in [
    'physiotherapy',
    'medical_office',
    'nail_salon',
    'hair_salon',
    'beauty_salon',
    'wellness',
    'other',
    'unknown',
  ]) {
    test(
      'only physiotherapy and medical offices show medical fields: $type',
      () async {
        final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'data': {
                  'store': {
                    'storeType': {'code': type},
                    'features': [
                      {'feature_key': 'medical_records', 'enabled': true},
                    ],
                  },
                },
              }),
              200,
            ),
          ),
        );
        final store = StoreProvider(
          repository: StoreRepository(apiClient: api),
        );
        expect(store.showMedicalFields, isFalse);
        await store.refresh();
        expect(
          store.showMedicalFields,
          ['physiotherapy', 'medical_office'].contains(type),
        );
        store.dispose();
      },
    );
  }

  test(
    'a late response from a previous store cannot reveal medical fields',
    () async {
      final first = Completer<http.Response>();
      var requests = 0;
      final api = _SessionApi(
        client: MockClient((_) async {
          requests++;
          if (requests == 1) return first.future;
          return http.Response(
            jsonEncode({
              'data': {
                'store': {
                  'storeType': {'code': 'nail_salon'},
                },
              },
            }),
            200,
          );
        }),
      );
      final store = StoreProvider(repository: StoreRepository(apiClient: api));
      final oldRequest = store.refresh();
      await Future<void>.delayed(Duration.zero);
      api.revision++;
      api.sessions.add(api.revision);
      await Future<void>.delayed(Duration.zero);
      await store.refresh();
      first.complete(
        http.Response(
          jsonEncode({
            'data': {
              'store': {
                'storeType': {'code': 'physiotherapy'},
              },
            },
          }),
          200,
        ),
      );
      await oldRequest;
      expect(store.showMedicalFields, isFalse);
      store.dispose();
      await api.sessions.close();
    },
  );

  test(
    'medical visibility resets immediately when the active session changes',
    () async {
      final api = _SessionApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': {
                'store': {
                  'storeType': {'code': 'physiotherapy'},
                },
              },
            }),
            200,
          ),
        ),
      );
      final store = StoreProvider(repository: StoreRepository(apiClient: api));
      await store.refresh();
      expect(store.showMedicalFields, isTrue);
      api.revision++;
      expect(store.showMedicalFields, isFalse);
      store.dispose();
      await api.sessions.close();
    },
  );

  for (final width in [390.0, 768.0, 1280.0]) {
    for (final type in ['nail_salon', 'physiotherapy', 'medical_office']) {
      testWidgets(
        'customer medical fields and safe saving at $width for $type',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final medical = type != 'nail_salon';
          final client = <String, dynamic>{
            'uuid': 'client',
            'first_name': 'Test',
            'last_name': 'Customer',
            'phone': '6900000000',
            'email': 'client@example.com',
            'address': 'Original address',
            'amka': '12345678901',
            'owes': '0',
            'date_of_birth': '1990-01-01',
            'client_description': ['Existing note'],
            'custom_fields': {
              'heart': true,
              'mainIssue': 'Existing issue',
              'allergies': 'Existing allergy',
            },
          };
          final appointment = {
            'uuid': 'booking',
            'client_record': client,
            'start_time': '2026-11-25T08:00:00Z',
            'paid': 0,
          };
          final writes = <Map<String, dynamic>>[];
          final api = ApiClient(
            baseUrl: 'http://localhost/api/v1',
            client: MockClient((request) async {
              Object data = [];
              if (request.url.path.endsWith('/store')) {
                data = {
                  'store': {
                    'storeType': {'code': type},
                  },
                };
              } else if (request.url.path.endsWith('/store/client-fields')) {
                data = [
                  for (final key in [
                    'heart',
                    'mainIssue',
                    'allergies',
                    'birthday',
                  ])
                    {'field_key': key, 'is_active': true},
                ];
              } else if (request.method == 'PUT') {
                writes.add(jsonDecode(request.body) as Map<String, dynamic>);
                data = client;
              } else if (request.url.path.contains('/appointments')) {
                data = [appointment];
              } else if (request.url.path.endsWith('/client')) {
                data = [client];
              }
              return http.Response(jsonEncode({'data': data}), 200);
            }),
          );
          final repository = SearchEditUserRepository(apiClient: api);
          final search = SearchUserProvider(
            searchEditUserRepository: repository,
          );
          final store = StoreProvider(
            repository: StoreRepository(apiClient: api),
          );
          await store.refresh();
          final customer = AppointMent.fromJson(client);
          final Widget card = width < 600
              ? mobile.CustomerCard(customer: customer, title: 'Customer')
              : width < 1000
              ? tablet.CustomerCard(customer: customer, title: 'Customer')
              : desktop.CustomerCard(customer: customer);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider.value(value: repository),
                Provider(create: (_) => AppointmentRepository(apiClient: api)),
                ChangeNotifierProvider.value(value: search),
                ChangeNotifierProvider.value(value: store),
                ChangeNotifierProvider(create: (_) => ToggleScreenProvider()),
              ],
              child: MaterialApp(
                theme: buildAppTheme(Brightness.light),
                home: Scaffold(body: card),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final amka = find.byWidgetPredicate(
            (widget) => widget is CustomTextForm && widget.labelText == 'ΑΜΚΑ',
          );
          expect(amka, medical ? findsOneWidget : findsNothing);
          if (medical) {
            expect(tester.widget<CustomTextForm>(amka).initial, '12345678901');
          }
          for (final label in [
            'Κύριο Πρόβλημα',
            'Φαρμακευτική αγωγή',
            'Αλλεργίες',
            'Ημ.Έναρξης Συμπτωμάτων',
            'Παραπέμπον Ιατρός',
            'Χειρουργεία (παρελθόν)',
            'Χειρουργεία (τωρινό)',
            'Κινητικάν/λειτουργικά ελλείμματα',
          ]) {
            expect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is CustomTextForm && widget.labelText == label,
              ),
              medical && width != 768 ? findsOneWidget : findsNothing,
              reason: label,
            );
          }
          expect(find.text('Existing note'), findsOneWidget);
          final save = find.text('Αποθήκευση');
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(writes, hasLength(1));
          final body = writes.single;
          if (medical) {
            expect(body['amka'], '12345678901');
          } else {
            expect(body.containsKey('amka'), isFalse);
            final fields = body['custom_fields'] as Map? ?? {};
            expect(fields.containsKey('heart'), isFalse);
            expect(fields.containsKey('mainIssue'), isFalse);
            expect(fields.containsKey('allergies'), isFalse);
          }
          expect(body['address'], 'Original address');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          store.dispose();
          search.dispose();
        },
      );
    }
  }

  for (final width in [390.0, 768.0, 1280.0]) {
    for (final type in ['nail_salon', 'medical_office']) {
      testWidgets(
        'shared profile hides AMKA without modifying it at $width for $type',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final writes = <Map<String, dynamic>>[];
          final client = {
            'uuid': 'client',
            'first_name': 'Test',
            'last_name': 'Customer',
            'amka': '12345678901',
          };
          final api = ApiClient(
            baseUrl: 'http://localhost/api/v1',
            client: MockClient((request) async {
              if (request.method == 'PUT') {
                writes.add(jsonDecode(request.body) as Map<String, dynamic>);
                return http.Response(jsonEncode({'data': client}), 200);
              }
              return http.Response(
                jsonEncode({
                  'data': {
                    'store': {
                      'storeType': {'code': type},
                    },
                  },
                }),
                200,
              );
            }),
          );
          final store = StoreProvider(
            repository: StoreRepository(apiClient: api),
          );
          await store.refresh();
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider.value(value: api),
                ChangeNotifierProvider.value(value: store),
              ],
              child: MaterialApp(
                theme: buildAppTheme(Brightness.light),
                home: Scaffold(body: CustomerProfileForm(customer: client)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Πρόσθετα στοιχεία'));
          await tester.pumpAndSettle();
          final amka = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == 'ΑΜΚΑ (όπου χρειάζεται)',
          );
          expect(
            amka,
            type == 'medical_office' ? findsOneWidget : findsNothing,
          );
          final save = find.widgetWithText(FilledButton, 'Αποθήκευση');
          await tester.scrollUntilVisible(
            save,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(save);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(writes, hasLength(1));
          expect(writes.single.containsKey('amka'), type == 'medical_office');
          if (type == 'medical_office') {
            expect(writes.single['amka'], '12345678901');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          store.dispose();
        },
      );
    }
  }
}
