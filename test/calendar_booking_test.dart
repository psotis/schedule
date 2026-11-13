import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_editor.dart';
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('double-tap creates a booking at the selected slot at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      var failSave = true;
      final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            Object data = [];
            if (request.url.path.endsWith('/client')) {
              data = [
                {
                  'uuid': 'client',
                  'first_name': 'Test',
                  'last_name': 'Customer'
                }
              ];
            }
            if (request.url.path.contains('/store')) data = {};
            if (request.method == 'POST' &&
                request.url.path.endsWith('/client')) {
              data = {
                'uuid': 'client',
                'first_name': 'Test',
                'last_name': 'Customer'
              };
            }
            if (request.method == 'POST' &&
                request.url.path.endsWith('/appointment')) {
              saved = jsonDecode(request.body) as Map<String, dynamic>;
              if (failSave) {
                return http.Response('{"message":"Booking failed"}', 409);
              }
              data = {'uuid': 'new-booking'};
            }
            return http.Response(jsonEncode({'data': data}), 200);
          }));
      final preferences = UiPreferencesProvider(
          repository: UiPreferencesRepository(apiClient: api));
      await preferences.setValue('calendar_layout', 'day');
      final employees = EmployeeProvider(
          employeeRepository: EmployeeRepository(apiClient: api));
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider.value(value: api),
            Provider(create: (_) => AppointmentRepository(apiClient: api)),
            Provider(create: (_) => AddAppointmentRepository(apiClient: api)),
            ChangeNotifierProvider.value(value: employees),
            ChangeNotifierProvider.value(value: preferences),
          ],
          child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: const Scaffold(body: SyncFusionCalendar()))));
      await tester.pumpAndSettle();
      final calendarFinder = find.byType(SfCalendar);
      if (width > 600) {
        final initialCalendarWidth = tester.getSize(calendarFinder).width;
        final initialPanelWidth = tester
            .getSize(find.byKey(const ValueKey('calendar-today-panel')))
            .width;
        tester.view.physicalSize = Size(width + 160, 900);
        await tester.pumpAndSettle();
        expect(
            tester
                .getSize(find.byKey(const ValueKey('calendar-today-panel')))
                .width,
            closeTo(initialPanelWidth + 160 / 3, 1));
        expect(tester.getSize(calendarFinder).width,
            closeTo(initialCalendarWidth + 160 * 2 / 3, 1));
      }
      final calendar = tester.widget<SfCalendar>(calendarFinder);
      final size = tester.getSize(calendarFinder);
      Offset? slot;
      DateTime? selected;
      for (double y = 160; y < size.height - 20; y += 25) {
        final position = Offset(size.width * .6, y);
        final details =
            calendar.controller!.getCalendarDetailsAtOffset!(position);
        if (details?.targetElement == CalendarElement.calendarCell &&
            details?.date != null) {
          slot = position;
          selected = details!.date;
          break;
        }
      }
      expect(slot, isNotNull);
      final point = tester.getTopLeft(calendarFinder) + slot!;
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentEditor), findsOneWidget);
      expect(find.text(DateFormat('dd/MM/yyyy HH:mm').format(selected!)),
          findsOneWidget);
      for (final entry in {'Όνομα': 'Test', 'Επώνυμο': 'Customer'}.entries) {
        await tester.enterText(
            find.byWidgetPredicate((widget) =>
                widget is TextField &&
                widget.decoration?.labelText == entry.key),
            entry.value);
      }
      final saveButton =
          find.widgetWithText(FilledButton, 'Αποθήκευση ραντεβού');
      await tester.scrollUntilVisible(saveButton, 250,
          scrollable: find
              .descendant(
                  of: find.byType(AppointmentEditor),
                  matching: find.byType(Scrollable))
              .first);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentEditor), findsOneWidget,
          reason: 'Failure keeps the form open');
      failSave = false;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(
          DateTime.parse(saved!['start_time'] as String).toLocal(), selected);
      expect(find.byType(AppointmentEditor), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      employees.dispose();
      preferences.dispose();
    });
  }
}
