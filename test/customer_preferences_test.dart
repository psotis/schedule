import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/screens/responsive_ui/customer/customer_preferences.dart';
import 'package:scheldule/screens/responsive_ui/settings/customer_field_settings.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

class _PreferenceApi extends ApiClient {
  _PreferenceApi({required super.client})
    : super(baseUrl: 'http://localhost/api/v1');
  final events = StreamController<void>.broadcast();
  final sessions = StreamController<int>.broadcast();
  int revision = 0;
  @override
  Stream<void> watch(String resource) => events.stream;
  @override
  Stream<int> get sessionChanges => sessions.stream;
  @override
  int get sessionRevision => revision;
}

Map<String, dynamic> _field(
  String key,
  String label, {
  String type = 'text',
  String group = 'nail_salon',
  Object value = '',
  List<Map<String, dynamic>> options = const [],
  Map<String, dynamic> settings = const {},
  bool active = true,
}) => {
  'id': key,
  'field_key': key,
  'label': label,
  'data_type': type,
  'field_group': group,
  'default_value': value,
  'options': options,
  'settings': settings,
  'is_active': active,
};

List<Map<String, dynamic>> _fields() => [
  _field(
    'pref_employee',
    'Προτιμώμενος εργαζόμενος',
    group: 'shared',
    type: 'select',
    value: 'not_specified',
    options: [
      {'value': 'not_specified', 'label': 'Δεν έχει οριστεί'},
    ],
    settings: {'reference': 'employee'},
  ),
  _field(
    'pref_services',
    'Προτιμώμενες υπηρεσίες',
    group: 'shared',
    type: 'multiselect',
    value: [],
    settings: {'reference': 'services'},
  ),
  _field(
    'pref_days',
    'Προτιμώμενες ημέρες',
    group: 'shared',
    type: 'multiselect',
    value: [],
    options: [
      {'value': '1', 'label': 'Δευτέρα'},
      {'value': '5', 'label': 'Παρασκευή'},
    ],
  ),
  _field(
    'pref_visit_interval',
    'Συνήθης επίσκεψη κάθε (ημέρες)',
    group: 'shared',
    settings: {'positive_integer': true},
  ),
  _field('nails_shape', 'Προτιμώμενο σχήμα νυχιών'),
  _field('nails_colours', 'Αγαπημένα χρώματα'),
  _field('nails_style', 'Στυλ / σχέδια'),
  _field('hidden', 'Κρυφή προτίμηση', active: false),
  _field(
    'heart',
    'Καρδιολογικά',
    group: 'custom',
    type: 'boolean',
    value: false,
  ),
];

Finder _textField(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  for (final width in [390.0, 768.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'preferences render and save only edited fields at $width in $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final writes = <Map<String, dynamic>>[];
          final values = <String, dynamic>{
            'nails_shape': 'Αμυγδαλωτό',
            'hidden': 'Keep this value',
          };
          final api = _PreferenceApi(
            client: MockClient((request) async {
              Object data = [];
              if (request.method == 'PUT') {
                final body = Map<String, dynamic>.from(
                  jsonDecode(request.body),
                );
                writes.add(body);
                values.addAll(Map<String, dynamic>.from(body['custom_fields']));
                data = {};
              } else if (request.url.path.endsWith('/store/client-fields')) {
                data = _fields();
              } else if (request.url.path.endsWith('/custom-fields')) {
                data = values.entries
                    .map(
                      (entry) => {
                        'field_definition_id': entry.key,
                        'value': entry.value,
                      },
                    )
                    .toList();
              } else if (request.url.path.endsWith('/employee')) {
                data = [
                  {
                    'uuid': 'employee',
                    'first_name': 'Test',
                    'last_name': 'Employee',
                  },
                ];
              } else if (request.url.path.endsWith('/services')) {
                data = [
                  {'id': 'service', 'name': 'Περιποίηση άκρων με μεγάλο όνομα'},
                ];
              }
              return http.Response(jsonEncode({'data': data}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
            }),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: CustomerPreferences(
                    customerId: 'client',
                    apiClient: api,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Κρυφή προτίμηση'), findsNothing);
          expect(find.text('Καρδιολογικά'), findsNothing);
          expect(find.text('Αμυγδαλωτό'), findsOneWidget);
          final shape = _textField('Προτιμώμενο σχήμα νυχιών');
          await tester.ensureVisible(shape);
          await tester.enterText(shape, 'Τετράγωνο');
          api.events.add(null); // A server refresh must not discard a draft.
          await tester.pumpAndSettle();
          expect(find.text('Τετράγωνο'), findsOneWidget);
          final save = find.text('Αποθήκευση προτιμήσεων');
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(writes, [
            {
              'custom_fields': {'nails_shape': 'Τετράγωνο'},
            },
          ]);
          expect(values['hidden'], 'Keep this value');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await api.events.close();
          await api.sessions.close();
        },
      );
    }
  }

  for (final width in [390.0, 768.0, 1280.0]) {
    testWidgets(
      'owner can hide and restore fields without changing customer values at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var visible = true;
        final writes = <Map<String, dynamic>>[];
        final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            if (request.method == 'PUT') {
              final body = Map<String, dynamic>.from(jsonDecode(request.body));
              writes.add(body);
              visible = body['is_active'] as bool;
            }
            return http.Response(
              jsonEncode({
                'data': [
                  _field(
                    'nails_shape',
                    'Προτιμώμενο σχήμα νυχιών',
                    active: visible,
                  ),
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        await tester.pumpWidget(
          Provider.value(
            value: api,
            child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: const Scaffold(body: CustomerFieldSettings()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(visible, isFalse);
        expect(find.text('Κρυφό — τα στοιχεία διατηρούνται'), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(visible, isTrue);
        expect(writes, [
          {'is_active': false},
          {'is_active': true},
        ]);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'a session change clears prior customer data and ignores stale responses',
    (tester) async {
      final pending = Completer<http.Response>();
      var loads = 0;
      final api = _PreferenceApi(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/store/client-fields')) {
            loads++;
            if (loads == 1) return pending.future;
          }
          return http.Response(jsonEncode({'data': []}), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerPreferences(customerId: 'client', apiClient: api),
          ),
        ),
      );
      await tester.pump();
      api.revision++;
      api.sessions.add(api.revision);
      await tester.pumpAndSettle();
      pending.complete(http.Response(jsonEncode({'data': _fields()}), 200, headers: {'content-type': 'application/json; charset=utf-8'}));
      await tester.pumpAndSettle();
      expect(find.text('Προτιμήσεις πελάτη'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await api.events.close();
      await api.sessions.close();
    },
  );
}
