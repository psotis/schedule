import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/appointment/appointment_provider.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:scheldule/screens/calendar/widgets/appointment_summary_dialog.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_editor.dart';
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'single-tap shows details; double-tap updates the same booking at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day, 10, 3);
        final client = {
          'uuid': 'client',
          'first_name': 'Test',
          'last_name': 'Customer',
        };
        final booking = {
          'uuid': 'existing-booking',
          'client_record': client,
          'start_time': start.toUtc().toIso8601String(),
          'end_time': start
              .add(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'total_duration_minutes': 60,
          'status': 'confirmed',
          'notes': 'Original note',
        };
        final writes = <http.Request>[];
        final availability = <http.Request>[];
        var failSave = true;
        final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            Object data = [];
            if (request.url.path.endsWith('/appointments')) data = [booking];
            if (request.url.path.endsWith('/client')) data = [client];
            if (request.url.path.contains('/store')) data = {};
            if (request.url.path.endsWith('/employee')) {
              availability.add(request);
            }
            if (request.method != 'GET' &&
                request.url.path.contains('/appointment')) {
              writes.add(request);
              if (failSave) {
                return http.Response(
                  '{"message":"Could not save booking"}',
                  409,
                );
              }
              data = {
                ...booking,
                ...jsonDecode(request.body) as Map<String, dynamic>,
              };
            }
            return http.Response(jsonEncode({'data': data}), 200);
          }),
        );
        final repository = AppointmentRepository(apiClient: api);
        final appointments = AppointmentProvider(
          appointmentRepository: repository,
        );
        final preferences = UiPreferencesProvider(
          repository: UiPreferencesRepository(apiClient: api),
        );
        await preferences.setValue('calendar_layout', 'day');
        final employees = EmployeeProvider(
          employeeRepository: EmployeeRepository(apiClient: api),
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: api),
              Provider.value(value: repository),
              Provider(create: (_) => AddAppointmentRepository(apiClient: api)),
              ChangeNotifierProvider.value(value: appointments),
              ChangeNotifierProvider.value(value: employees),
              ChangeNotifierProvider.value(value: preferences),
            ],
            child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: const Scaffold(body: SyncFusionCalendar()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final calendarFinder = find.byType(SfCalendar);
        for (final element
            in find
                .descendant(
                  of: calendarFinder,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          if (state.position.maxScrollExtent > 0) state.position.jumpTo(0);
        }
        await tester.pumpAndSettle();
        final calendar = tester.widget<SfCalendar>(calendarFinder);
        final size = tester.getSize(calendarFinder);
        Offset? appointmentPoint;
        for (double y = 100; y < size.height - 10; y += 5) {
          final point = Offset(size.width * .55, y);
          final details = calendar.controller!.getCalendarDetailsAtOffset!(
            point,
          );
          if (details?.targetElement == CalendarElement.appointment) {
            appointmentPoint = tester.getTopLeft(calendarFinder) + point;
            break;
          }
        }
        expect(appointmentPoint, isNotNull);
        await tester.tapAt(appointmentPoint!);
        await tester.pumpAndSettle();
        expect(find.byType(AppointmentSummaryDialog), findsOneWidget);
        expect(find.byType(AppointmentEditor), findsNothing);
        await tester.tap(find.text('Κλείσιμο'));
        await tester.pumpAndSettle();
        await tester.tapAt(appointmentPoint);
        await tester.pump(const Duration(milliseconds: 80));
        await tester.tapAt(appointmentPoint);
        await tester.pumpAndSettle();
        expect(find.byType(AppointmentEditor), findsOneWidget);
        expect(find.byType(AppointmentSummaryDialog), findsNothing);
        expect(
          tester
              .widget<AppointmentEditor>(find.byType(AppointmentEditor))
              .appointment!
              .id,
          'existing-booking',
        );
        expect(writes, isEmpty);
        final notes = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Σημειώσεις',
        );
        await tester.scrollUntilVisible(
          notes,
          200,
          scrollable: find
              .descendant(
                of: find.byType(AppointmentEditor),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.enterText(notes, 'Updated note');
        final save = find.widgetWithText(FilledButton, 'Αποθήκευση ραντεβού');
        await tester.scrollUntilVisible(
          save,
          200,
          scrollable: find
              .descendant(
                of: find.byType(AppointmentEditor),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(AppointmentEditor), findsOneWidget);
        expect(find.text('Could not save booking'), findsOneWidget);
        failSave = false;
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(AppointmentEditor), findsNothing);
        expect(writes.length, 2);
        for (final request in writes) {
          expect(request.method, 'PUT');
          expect(request.url.path, endsWith('/appointment/existing-booking'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(DateTime.parse(body['start_time'] as String).toLocal(), start);
          expect(
            DateTime.parse(body['end_time'] as String).toLocal(),
            start.add(const Duration(hours: 1)),
          );
          expect(body['notes'], 'Updated note');
          expect(body.containsKey('status'), isFalse);
          expect(body.containsKey('paid'), isFalse);
        }
        expect(
          availability.any(
            (request) =>
                request.url.queryParameters['exclude_appointment_id'] ==
                'existing-booking',
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        appointments.dispose();
        employees.dispose();
        preferences.dispose();
      },
    );
  }
}
