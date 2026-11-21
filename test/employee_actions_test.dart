import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/models/employee.dart';
import 'package:scheldule/providers/employee/empoyee_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/employee_repository.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/screens/responsive_ui/desktop/employee/widgets/employee_card.dart';
import 'package:scheldule/screens/responsive_ui/finance_access_gate.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 800.0, 1440.0]) {
    for (final failure in [false, true]) {
      testWidgets('employee removal waits for server at $width (failure: $failure)', (tester) async {
        tester.view.physicalSize = Size(width, width == 360 ? 640 : 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final response = Completer<http.Response>();
        var deletes = 0;
        var closed = false;
        final api = ApiClient(baseUrl: 'http://localhost/api/v1', client: MockClient((request) {
          deletes++;
          return response.future;
        }));
        final employee = Employee.fromJson({'uuid': 'employee', 'first_name': 'Test', 'last_name': 'Employee', 'amka': '123456789'});
        final provider = EmployeeProvider(employeeRepository: EmployeeRepository(apiClient: api));
        provider.employees = [employee];
        await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
          child: MaterialApp(theme: buildAppTheme(Brightness.light), home: Scaffold(
            body: EmployeeCard(employe: employee, onClose: () => closed = true)))));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Διαγραφή εργαζομένου'));
        await tester.pumpAndSettle();
        expect(find.text('Αφαίρεση από την ομάδα;'), findsOneWidget);
        expect(deletes, 0);
        await tester.tap(find.text('Ακύρωση'));
        await tester.pumpAndSettle();
        expect(deletes, 0);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Διαγραφή εργαζομένου'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Διαγραφή'));
        await tester.pumpAndSettle();
        expect(deletes, 1);
        expect(closed, false);
        expect(find.text('Ο εργαζόμενος αφαιρέθηκε από την ομάδα.'), findsNothing);
        response.complete(http.Response(jsonEncode(failure ? {'message': 'Cannot remove employee right now'} : {'data': {'is_active': false}}), failure ? 409 : 200));
        await tester.pumpAndSettle();
        expect(closed, !failure);
        expect(provider.employees.length, failure ? 1 : 0);
        expect(find.textContaining(failure ? 'Cannot remove employee right now' : 'Ο εργαζόμενος αφαιρέθηκε από την ομάδα.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });
    }
  }
  for (final hasPin in [false, true]) {
    testWidgets('finance word password works when configured: $hasPin', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <http.Request>[];
      final api = ApiClient(baseUrl: 'http://localhost/api/v1', client: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode({'data': {'has_pin': hasPin}}), 200);
      }));
      await tester.pumpWidget(Provider(create: (_) => TransactionRepository(apiClient: api),
        child: MaterialApp(theme: buildAppTheme(Brightness.light), home: Scaffold(
          body: FinanceAccessGate(destinationBuilder: (_) => const Scaffold(body: Text('Finance opened')))))));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (!hasPin) await tester.enterText(fields.at(0), 'Account-password');
      await tester.enterText(fields.at(hasPin ? 0 : 1), 'maimou');
      if (!hasPin) await tester.enterText(fields.at(2), 'maimou');
      final button = find.widgetWithText(FilledButton, hasPin ? 'Είσοδος στα οικονομικά' : 'Αποθήκευση & συνέχεια');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Finance opened'), findsOneWidget);
      expect(jsonDecode(requests.last.body)['pin'], 'maimou');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
