import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

void main() {
  testWidgets(
      'export the real calendar with fictional demonstration appointments',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fonts = FontLoader('IBMPlexSans');
    for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle
          .load('assets/google_fonts/ibm_plex_sans/IBMPlexSans-$face.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final names = ['Άννα', 'Νίκος', 'Ελένη'];
    final surnames = ['Κ.', 'Π.', 'Δ.'];
    final staff = ['Μαρία', 'Αλέξης', 'Έλενα'];
    final colors = ['#719d88', '#c79b7e', '#a392ba'];
    final services = ['Περιποίηση', 'Συνεδρία', 'Κούρεμα'];
    final appointments = [
      for (var i = 0; i < 3; i++)
        {
          'uuid': 'demo-booking-$i',
          'client_record': {
            'uuid': 'demo-client-$i',
            'first_name': names[i],
            'last_name': surnames[i]
          },
          'start_time': day
              .add(Duration(hours: 9 + i, minutes: i == 1 ? 30 : 0))
              .toUtc()
              .toIso8601String(),
          'end_time': day
              .add(Duration(hours: 10 + i, minutes: i == 1 ? 30 : 0))
              .toUtc()
              .toIso8601String(),
          'employee_id': 'demo-staff-$i',
          'employee': staff[i],
          'status': 'scheduled',
          'total_duration_minutes': 60,
          'service_items': [
            {
              'id': 'demo-line-$i',
              'service_name': services[i],
              'duration_minutes': 60
            }
          ],
        }
    ];
    final api = ApiClient(
        baseUrl: 'http://demo.invalid/api',
        client: MockClient((request) async {
          Object data = {};
          if (request.url.path.endsWith('/appointments')) data = appointments;
          if (request.url.path.endsWith('/employee')) {
            data = [
              for (var i = 0; i < 3; i++)
                {
                  'uuid': 'demo-staff-$i',
                  'first_name': staff[i],
                  'last_name': '',
                  'color': colors[i]
                }
            ];
          }
          return http.Response(jsonEncode({'data': data}), 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }));
    final preferences = UiPreferencesProvider(
        repository: UiPreferencesRepository(apiClient: api));
    await preferences.setValue('calendar_layout', 'day');
    final employees = EmployeeProvider(
        employeeRepository: EmployeeRepository(apiClient: api));
    final boundary = GlobalKey();
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider(create: (_) => AppointmentRepository(apiClient: api)),
          ChangeNotifierProvider.value(value: preferences),
          ChangeNotifierProvider.value(value: employees),
        ],
        child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            locale: const Locale('el'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: const [Locale('el'), Locale('en')],
            home: RepaintBoundary(
                key: boundary,
                child: const Scaffold(
                    body: Padding(
                        padding: EdgeInsets.all(16),
                        child: SyncFusionCalendar()))))));
    await tester.pumpAndSettle();
    final scrollables = find.descendant(
        of: find.byType(sf.SfCalendar),
        matching: find.byWidgetPredicate((widget) =>
            widget is Scrollable &&
            widget.axisDirection == AxisDirection.down));
    for (final element in scrollables.evaluate()) {
      final state = (element as StatefulElement).state as ScrollableState;
      if (state.position.maxScrollExtent > 0) {
        state.position.jumpTo(0);
      }
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('web/images/calendar-preview.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    preferences.dispose();
    employees.dispose();
  }, skip: !const bool.fromEnvironment('UPDATE_CALENDAR_PREVIEW'));
}
