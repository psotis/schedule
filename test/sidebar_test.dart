import 'dart:convert';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/repositories/appointment_repository.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/screens/calendar/syncfusion_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scheldule/main.dart' as app;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/providers/drawer_nav/drawer_provider.dart';
import 'package:scheldule/providers/themes/theme_provider.dart';
import 'package:scheldule/providers/ui_preferences/ui_preferences_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/ui_preferences_repository.dart';
import 'package:scheldule/screens/responsive_ui/widgets/web_app_shell.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app.prefs = await SharedPreferences.getInstance();
  });
  for (final layout in [AppShellLayout.desktop, AppShellLayout.tablet]) {
    testWidgets('sidebar toggles without replacing the page on $layout',
        (tester) async {
      tester.view.physicalSize =
          Size(layout == AppShellLayout.desktop ? 1280 : 768, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <Map<String, dynamic>>[];
      var appointmentReads = 0;
      final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            if (request.method == 'PUT') {
              writes.add(jsonDecode(request.body) as Map<String, dynamic>);
            }
            if (request.url.path.endsWith('/appointments')) appointmentReads++;
            final data = request.url.path.contains('/store') ? {} : [];
            return http.Response(jsonEncode({'data': data}), 200);
          }));
      final preferences = UiPreferencesProvider(
          repository: UiPreferencesRepository(apiClient: api));
      final auth = AuthProvider(authRepository: AuthRepository(apiClient: api));
      final employees = EmployeeProvider(
          employeeRepository: EmployeeRepository(apiClient: api));
      final drawer = DrawerProvider();
      final theme = ThemeProvider();
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider(create: (_) => AppointmentRepository(apiClient: api)),
            ChangeNotifierProvider.value(value: employees),
            ChangeNotifierProvider.value(value: preferences),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: drawer),
            ChangeNotifierProvider.value(value: theme),
          ],
          child: MaterialApp(
              home: WebAppShell(
                  layout: layout,
                  pageBuilder: (status, canManage) => const Column(children: [
                        TextField(key: ValueKey('page-field')),
                        Expanded(child: SyncFusionCalendar()),
                      ])))));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('page-field')), 'Keep my edits');
      tester.view.physicalSize = const Size(768, 850);
      await tester.pumpAndSettle();
      final readsBeforeToggling = appointmentReads;
      final initialCompact = layout == AppShellLayout.tablet;
      await tester.tap(
          find.byTooltip(initialCompact ? 'Ανάπτυξη μενού' : 'Σύμπτυξη μενού'));
      await tester.pumpAndSettle();
      expect(writes.last,
          {'sidebar_layout': initialCompact ? 'expanded' : 'compact'});
      expect(find.text('Keep my edits'), findsOneWidget);
      expect(
          find.byTooltip(initialCompact ? 'Σύμπτυξη μενού' : 'Ανάπτυξη μενού'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final width in [680.0, 1000.0, 768.0]) {
        tester.view.physicalSize = Size(width, 850);
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('calendar-today-panel'));
        final panelWidth = width == 1000 ? tester.getSize(panel).width : null;
        final calendarWidth = tester.getSize(find.byType(SfCalendar)).width;
        final compact =
            preferences.value('sidebar_layout', fallback: 'expanded') ==
                'compact';
        await tester
            .tap(find.byTooltip(compact ? 'Ανάπτυξη μενού' : 'Σύμπτυξη μενού'));
        await tester.pumpAndSettle();
        expect(find.byType(SfCalendar), findsOneWidget);
        if (panelWidth != null) {
          expect(panelWidth, closeTo((width - 280) / 3, 1));
          expect(tester.getSize(panel).width, closeTo(panelWidth, 1));
          expect(tester.getSize(find.byType(SfCalendar)).width,
              closeTo(calendarWidth + (compact ? -156 : 156), 1));
        }
        expect(find.text('Keep my edits'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(appointmentReads, readsBeforeToggling);
      await tester.pumpWidget(const SizedBox());
      employees.dispose();
      preferences.dispose();
      auth.dispose();
      drawer.dispose();
      theme.dispose();
    });
  }
}
