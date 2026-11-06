import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheldule/main.dart' as app;
import 'package:scheldule/models/appointment_model.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/themes/theme_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/add_appointment_repository.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/screens/responsive_ui/settings/business_settings.dart';
import 'package:scheldule/screens/responsive_ui/appointments/appointment_editor.dart';
import 'package:scheldule/screens/responsive_ui/customer/customer_profile_form.dart';
import 'package:scheldule/styling/themes/app_theme.dart';
import 'package:scheldule/screens/responsive_ui/widgets/section_tabs.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart'
    show MeetingDataSource;
import 'package:scheldule/screens/calendar/widgets/customer_side.dart'
    show AppointmentDetailFrame;
import 'package:syncfusion_flutter_calendar/calendar.dart' as calendar;

void main() {
  final employee = {
    'uuid': 'employee',
    'first_name': 'Test',
    'last_name': 'Employee'
  };
  final client = {
    'uuid': 'client',
    'first_name': 'Test',
    'last_name': 'Customer',
    'phone': '+30 690 123 4567'
  };
  List<http.Request> requests = [];

  ApiClient createApi() => ApiClient(
      baseUrl: 'http://localhost/api/v1',
      client: MockClient((request) async {
        requests.add(request);
        dynamic data;
        if (request.url.path.endsWith('/employee')) {
          data = [employee];
        } else if (request.url.path.endsWith('/client')) {
          data = [client];
        } else if (request.url.path.endsWith('/services')) {
          data = [
            {
              'id': 'service',
              'name': 'Test service',
              'price': 99,
              'duration_minutes': 30
            }
          ];
        } else if (request.url.path.endsWith('/reports/overview')) {
          data = {
            'totals': {},
            'services': [],
            'employees': [],
            'weekdays': [],
            'hours': [],
            'daily': []
          };
        } else if (request.method == 'PUT' ||
            request.url.path.endsWith('/appointment')) {
          data = {'uuid': 'appointment', 'client_record': client};
        } else {
          data = [];
        }
        return http.Response(jsonEncode({'data': data}), 200,
            headers: {'content-type': 'application/json'});
      }));

  Widget wrap(ApiClient api, Widget child) => MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          Provider(create: (_) => AddAppointmentRepository(apiClient: api)),
          Provider(create: (_) => AppointmentRepository(apiClient: api)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(body: child)),
      );

  setUp(() async {
    requests = [];
    SharedPreferences.setMockInitialValues({'theme': 'light'});
    app.prefs = await SharedPreferences.getInstance();
  });

  testWidgets(
      'recently started appointments with an AMKA render as ordinary calendar events',
      (tester) async {
    final now = DateTime(2026, 11, 6, 12, 30);
    final start = now.subtract(const Duration(minutes: 30));
    final appointment = AppointMent.fromJson({
      'uuid': 'recent-appointment',
      'client_record': {...client, 'amka': '26733'},
      'start_time': start.toUtc().toIso8601String(),
      'end_time':
          start.add(const Duration(minutes: 45)).toUtc().toIso8601String(),
      'total_duration_minutes': 45,
    });
    final source = MeetingDataSource.fromAppointments([appointment], {});
    expect(source.getRecurrenceRule(0), isEmpty);
    expect(source.getStartTime(0), start);
    expect(source.getEndTime(0), start.add(const Duration(minutes: 45)));
    final controller = calendar.CalendarController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: calendar.SfCalendar(
      controller: controller,
      view: calendar.CalendarView.day,
      initialDisplayDate: now,
      dataSource: source,
      timeSlotViewSettings:
          const calendar.TimeSlotViewSettings(startHour: 10, endHour: 15),
      appointmentBuilder: (context, details) => Text(source.getSubject(0)),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Test Customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final assignEmployee in [false, true]) {
    testWidgets(
        'an appointment without services can be saved with employee=$assignEmployee',
        (tester) async {
      await tester.pumpWidget(wrap(createApi(), const AppointmentEditor()));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byWidgetPredicate((widget) =>
              widget is TextField && widget.decoration?.labelText == 'Όνομα'),
          'Test');
      await tester.enterText(
          find.byWidgetPredicate((widget) =>
              widget is TextField && widget.decoration?.labelText == 'Επώνυμο'),
          'Customer');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final employeeField = find.byType(DropdownButtonFormField<Employee?>);
      await tester.scrollUntilVisible(employeeField, 200,
          scrollable: find.byType(Scrollable).first);
      if (assignEmployee) {
        await tester.tap(employeeField);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test Employee').last);
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('Αποθήκευση ραντεβού'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Αποθήκευση ραντεβού'));
      await tester.pumpAndSettle();
      final request = requests.lastWhere((request) => request.method == 'POST');
      final body = jsonDecode(request.body) as Map;
      expect(body['services'], isEmpty);
      expect(body['employee_id'], assignEmployee ? 'employee' : null);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'appointment details have a scrollable body and a visible footer on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
            body: AppointmentDetailFrame(
          title: 'Test Customer',
          subtitle: '06/11/2026 • 12:00 • 45′',
          appointmentCount: 6,
          actions: Wrap(children: [
            FilledButton(onPressed: () {}, child: const Text('Save changes'))
          ]),
          child:
              const SizedBox(height: 1500, child: Text('Appointment fields')),
        ))));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Save changes').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('section pages ignore swipes but switch when their tab is tapped',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: DefaultTabController(
      length: 2,
      child: Builder(
          builder: (context) => Scaffold(
                  body: SectionTabs(
                controller: DefaultTabController.of(context),
                tabs: const [
                  SectionTabItem('First', Icons.event),
                  SectionTabItem('Second', Icons.people)
                ],
                children: const [
                  Center(child: Text('First page')),
                  Center(child: Text('Second page'))
                ],
              ))),
    )));
    await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('First page').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expect(find.text('Second page').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'customer search normalizes phone numbers and appointment models keep fractional payments',
      () {
    final customer = AppointMent.fromJson(client);
    expect(customer.matchesSearch('6901234567'), isTrue);
    expect(customer.matchesSearch('Customer'), isTrue);
    final appointment = AppointMent.fromJson({
      'uuid': 'appointment',
      'client_record': client,
      'client_id': 'client',
      'start_time': '2026-11-06T08:00:00Z',
      'end_time': '2026-11-06T09:30:00Z',
      'paid': '10.25',
    });
    expect(appointment.paidAmount, 10.25);
    expect(appointment.effectiveDurationMinutes, 90);
    expect(appointment.copyWith(notes: 'updated').clientId, 'client');
    expect(appointment.copyWith(notes: 'updated').paidAmount, 10.25);
  });

  for (final width in [360.0, 1024.0]) {
    testWidgets(
        'schedule dialog renders and saving preserves team tab at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(createApi(), const BusinessSettings()));
      await tester.pumpAndSettle();
      final teamTab = find.widgetWithText(Tab, 'Ομάδα');
      await tester.ensureVisible(teamTab);
      await tester.tap(teamTab);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(TabBarView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('Ικανότητες και ωράριο ομάδας'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Ωράριο'));
      await tester.pumpAndSettle();
      expect(find.text('Ωράριο: Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Αποθήκευση'));
      await tester.pumpAndSettle();
      expect(find.text('Ικανότητες και ωράριο ομάδας'), findsOneWidget);
      expect(
          requests.any((request) =>
              request.method == 'PUT' &&
              request.url.path.endsWith('/availability')),
          isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'editing an appointment sends its historical service snapshot, not current catalog values',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appointment = AppointMent.fromJson({
      'uuid': 'appointment',
      'client_id': 'client',
      'client_record': client,
      'start_time': '2026-11-06T08:00:00Z',
      'end_time': '2026-11-06T09:30:00Z',
      'total_price': 35.25,
      'total_duration_minutes': 90,
      'service_items': [
        {
          'id': 'line',
          'service_id': 'service',
          'service_name': 'Test service',
          'price': 35.25,
          'duration_minutes': 90,
          'employee_uuid': 'employee',
          'employee': employee
        }
      ],
    });
    var saved = false;
    await tester.pumpWidget(wrap(
        createApi(),
        AppointmentEditor(
            appointment: appointment, onSaved: () => saved = true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Αποθήκευση ραντεβού'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Αποθήκευση ραντεβού'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(saved, isTrue);
    final update = requests.lastWhere((request) => request.method == 'PUT');
    final body = jsonDecode(update.body) as Map;
    expect(body['services'][0]['id'], 'line');
    expect(body['services'][0]['price'], 35.25);
    expect(body['services'][0]['duration_minutes'], 90);
    expect(
        requests
            .where((request) => request.url.path.endsWith('/employee'))
            .every((request) =>
                request.url.queryParameters['exclude_appointment_id'] ==
                'appointment'),
        isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'store admin can create credentials linked to an existing employee on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(createApi(), const BusinessSettings()));
    await tester.pumpAndSettle();
    final accessTab = find.widgetWithText(Tab, 'Πρόσβαση');
    await tester.ensureVisible(accessTab);
    await tester.tap(accessTab);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Προσθήκη χρήστη'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Employee>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Employee').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byWidgetPredicate((widget) =>
            widget is TextField && widget.decoration?.labelText == 'Email'),
        'staff@example.test');
    await tester.enterText(
        find.byWidgetPredicate(
            (widget) => widget is TextField && widget.obscureText),
        'test-password-123');
    await tester.tap(find.widgetWithText(FilledButton, 'Προσθήκη'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final request = requests.lastWhere((request) => request.method == 'POST');
    expect(request.url.path.endsWith('/store/employee-accounts'), isTrue);
    expect(jsonDecode(request.body)['employee_id'], 'employee');
    expect(jsonDecode(request.body)['email'], 'staff@example.test');
    expect(find.text('Πρόσβαση ομάδας'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'duplicate phone opens the existing customer rather than posting another customer',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var created = 0;
    final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.method == 'POST') created++;
          final data = request.url.path.endsWith('/client-duplicate')
              ? client
              : {'client': client, 'totals': {}, 'services': [], 'history': []};
          return http.Response(jsonEncode({'data': data}), 200);
        }));
    await tester.pumpWidget(wrap(api, const CustomerProfileForm()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Όνομα'), 'New');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Επώνυμο'), 'Customer');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Κινητό'), '6901234567');
    await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Αποθήκευση'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.widgetWithText(FilledButton, 'Αποθήκευση'));
    await tester.pumpAndSettle();
    expect(
        find.text('Υπάρχει ήδη καρτέλα με αυτό το τηλέφωνο'), findsOneWidget);
    await tester.tap(find.text('Άνοιγμα καρτέλας'));
    await tester.pumpAndSettle();
    expect(created, 0);
    expect(tester.takeException(), isNull);
    expect(find.text('Customer ID: client'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
