import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';
import 'package:scheldule/screens/responsive_ui/settings/monthly_report_settings.dart';
import 'package:scheldule/screens/responsive_ui/widgets/finance_report_button.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('monthly report settings save only after successful response at $width $brightness', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var saves = 0;
        final api = ApiClient(baseUrl: 'http://localhost/api/v1', client: MockClient((request) async {
          if (request.method == 'GET') return http.Response(jsonEncode({'data': {'enabled': false, 'recipient_email': 'owner@example.test', 'timezone': 'Europe/Athens'}}), 200);
          expect(jsonDecode(request.body), {'enabled': true});
          saves++;
          return http.Response(jsonEncode({'message': 'Temporary error'}), saves == 1 ? 503 : 200);
        }));
        await tester.pumpWidget(Provider.value(value: api, child: MaterialApp(theme: buildAppTheme(brightness),
          home: const Scaffold(body: SingleChildScrollView(child: MonthlyReportSettings())))));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SwitchListTile)); await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, false);
        expect(find.text('Temporary error'), findsOneWidget);
        await tester.tap(find.byType(SwitchListTile)); await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, true);
        expect(saves, 2); expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('finance download uses selected month and waits for authenticated PDF response', (tester) async {
    final response = Completer<http.Response>();
    var requests = 0;
    Uint8List? saved;
    String? filename;
    final api = ApiClient(baseUrl: 'http://localhost/api/v1', client: MockClient((request) {
      requests++; expect(request.url.queryParameters['month'], '2026-02');
      expect(request.headers['Accept'], 'application/pdf');
      return response.future;
    }));
    await tester.pumpWidget(MultiProvider(providers: [Provider.value(value: api), Provider(create: (_) => TransactionRepository(apiClient: api))],
      child: MaterialApp(home: Scaffold(body: FinanceReportButton(year: 2026, month: 2, save: (bytes, name) async { saved = bytes; filename = name; })))));
    await tester.tap(find.byType(OutlinedButton)); await tester.pump();
    expect(saved, isNull); expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
    response.complete(http.Response('%PDF-fixture', 200, headers: {'content-type': 'application/pdf'}));
    await tester.pumpAndSettle();
    expect(requests, 1); expect(ascii.decode(saved!), '%PDF-fixture'); expect(filename, 'rantevia-finance-2026-02.pdf');
    expect(tester.takeException(), isNull);
  });
  test('invalid report and denied responses never become downloaded PDF files', () async {
    for (final status in [200, 403]) {
      final api = ApiClient(baseUrl: 'http://localhost/api/v1', client: MockClient((_) async => http.Response('{"message":"Denied"}', status, headers: {'content-type': 'text/html'})));
      await expectLater(api.getPdf('/finance/reports/monthly'), throwsA(isA<ApiException>()));
    }
  });
}
