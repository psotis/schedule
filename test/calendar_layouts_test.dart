import 'dart:convert';
import 'dart:async';
import 'package:scheldule/repositories/store_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/appointment_model.dart' as model;
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:scheldule/screens/calendar/widgets/calendar_layout_picker.dart';
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:scheldule/repositories/search_edit_user_repository.dart';
import 'package:scheldule/screens/responsive_ui/mobile/customer/widgets/customer_list.dart'
    as mobile_customer;
import 'package:scheldule/screens/responsive_ui/mobile/employee/widgets/employee_list.dart'
    as mobile_employee;
import 'package:scheldule/screens/responsive_ui/tablet/customer/widgets/customer_list.dart'
    as tablet_customer;
import 'package:scheldule/screens/responsive_ui/tablet/employee/widgets/employee_list.dart'
    as tablet_employee;
import 'package:scheldule/screens/responsive_ui/desktop/customer/widgets/customer_list.dart'
    as desktop_customer;
import 'package:scheldule/screens/responsive_ui/desktop/employee/widgets/employee_list.dart'
    as desktop_employee;

class _StoreEventsApi extends ApiClient {
  final storeEvents = StreamController<void>.broadcast();
  _StoreEventsApi({required super.baseUrl, required super.client});
  @override
  Stream<void> watch(String resource) =>
      resource == 'store' ? storeEvents.stream : super.watch(resource);
}

void main() {
  test(
      'store working-day settings retain the legacy fallback and accept Sunday',
      () {
    expect(StoreRepository.workingDaysFromSettings({}), [1, 2, 3, 4, 5]);
    expect(StoreRepository.workingDaysFromSettings({'working_days': []}),
        [1, 2, 3, 4, 5]);
    expect(
        StoreRepository.workingDaysFromSettings({
          'working_days': [7, 2, 6]
        }),
        [2, 6, 7]);
  });
  for (final width in [360.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('calendar layouts switch and fit at $width in $brightness',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final start = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day, 9);
        final writes = <Map<String, dynamic>>[];
        var workingDays = [2, 3, 4, 5, 6];
        final api = _StoreEventsApi(
            baseUrl: 'http://localhost/api/v1',
            client: MockClient((request) async {
              Object data = [];
              if (request.url.path.endsWith('/appointments')) {
                data = [
                  {
                    'uuid': 'booking',
                    'client_record': {
                      'uuid': 'client',
                      'first_name': 'Test',
                      'last_name': 'Customer'
                    },
                    'start_time': start.toUtc().toIso8601String(),
                    'end_time': start
                        .add(const Duration(minutes: 45))
                        .toUtc()
                        .toIso8601String(),
                    'total_duration_minutes': 45,
                    'status': 'scheduled',
                  }
                ];
              } else if (request.url.path.endsWith('/store')) {
                data = {
                  'store': {
                    'settings': {'working_days': workingDays}
                  }
                };
              } else if (request.url.path.endsWith('/store/preferences')) {
                if (request.method == 'PUT') {
                  writes.add(jsonDecode(request.body) as Map<String, dynamic>);
                }
                data = {};
              }
              return http.Response(jsonEncode({'data': data}), 200);
            }));
        final preferences = UiPreferencesProvider(
            repository: UiPreferencesRepository(apiClient: api));
        final employees = EmployeeProvider(
            employeeRepository: EmployeeRepository(apiClient: api));
        await tester.pumpWidget(MultiProvider(
            providers: [
              Provider.value(value: api),
              Provider(create: (_) => AppointmentRepository(apiClient: api)),
              ChangeNotifierProvider.value(value: employees),
              ChangeNotifierProvider.value(value: preferences),
            ],
            child: MaterialApp(
                theme: buildAppTheme(brightness),
                home: const Scaffold(body: SyncFusionCalendar()))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final layout in CalendarLayout.values) {
          await preferences.setValue('calendar_layout', layout.key);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: layout.key);
          expect(tester.widget<SfCalendar>(find.byType(SfCalendar)).view,
              layout.view);
          expect(find.byType(CalendarLayoutPicker), findsOneWidget);
          expect(
              tester
                  .widget<SfCalendar>(find.byType(SfCalendar))
                  .timeSlotViewSettings
                  .nonWorkingDays,
              [1, 7]);
          if (layout == CalendarLayout.resources) {
            final source =
                tester.widget<SfCalendar>(find.byType(SfCalendar)).dataSource!;
            expect(
                source.resources!
                    .any((resource) => resource.id == 'unassigned'),
                isTrue);
            expect(source.getResourceIds(0), ['unassigned']);
          }
        }
        expect(writes.last['calendar_layout'], 'dailySummary');
        await preferences.setValue('calendar_layout', 'workWeek');
        await tester.pumpAndSettle();
        workingDays = [1, 4, 7];
        api.storeEvents.add(null);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<SfCalendar>(find.byType(SfCalendar))
                .timeSlotViewSettings
                .nonWorkingDays,
            [2, 3, 5, 6]);
        await tester.pumpWidget(const SizedBox());
        employees.dispose();
        preferences.dispose();
        await api.storeEvents.close();
      });
    }
  }

  for (final entry in <(double, Widget, String)>[
    (360, const mobile_customer.CustomerList(), 'customers_view'),
    (360, const mobile_employee.EmployeeList(), 'employees_view'),
    (700, const tablet_customer.CustomerList(), 'customers_view'),
    (700, const tablet_employee.EmployeeList(), 'employees_view'),
    (1100, const desktop_customer.CustomerList(), 'customers_view'),
    (1100, const desktop_employee.EmployeeList(), 'employees_view'),
  ]) {
    testWidgets('list/grid choice works for ${entry.$3} at ${entry.$1}',
        (tester) async {
      tester.view.physicalSize = Size(entry.$1, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            final data = request.method == 'PUT'
                ? {}
                : [
                    {
                      'uuid': 'record',
                      'first_name': 'Test',
                      'last_name': 'Customer',
                      'email': 'test@example.test',
                      'phone': '6901234567',
                    }
                  ];
            return http.Response(jsonEncode({'data': data}), 200);
          }));
      final preferences = UiPreferencesProvider(
          repository: UiPreferencesRepository(apiClient: api));
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider(create: (_) => EmployeeRepository(apiClient: api)),
            Provider(create: (_) => SearchEditUserRepository(apiClient: api)),
            ChangeNotifierProvider.value(value: preferences),
          ],
          child: MaterialApp(
              theme: buildAppTheme(Brightness.dark),
              home: Scaffold(body: entry.$2))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Πλέγμα'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
      expect(preferences.value(entry.$3, fallback: 'list'), 'grid');
      await tester.tap(find.text('Λίστα'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsNothing);
      await tester.pumpWidget(const SizedBox());
      preferences.dispose();
    });
  }

  test(
      'resource grouping retains original booking IDs and multiple employee assignments',
      () {
    final appointment = _bookingWithEmployees();
    final source = MeetingDataSource.fromAppointments([appointment], {},
        groupByEmployee: true);
    expect(source.getId(0), 'booking');
    expect(source.getRecurrenceRule(0), isEmpty);
    expect(source.getResourceIds(0),
        containsAll(['first-employee', 'second-employee']));
    expect(source.resources!.map((resource) => resource.id),
        containsAll(['first-employee', 'second-employee', 'unassigned']));
  });
}

model.AppointMent _bookingWithEmployees() => model.AppointMent.fromJson({
      'uuid': 'booking',
      'start_time': '2026-11-06T09:00:00Z',
      'end_time': '2026-11-06T10:00:00Z',
      'employee_record': {'uuid': 'first-employee', 'first_name': 'First'},
      'service_items': [
        {'id': 'line-one', 'employee_uuid': 'first-employee'},
        {'id': 'line-two', 'employee_uuid': 'second-employee'},
      ],
    });
