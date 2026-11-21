import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scheldule/providers/billing/billing_provider.dart';
import 'package:scheldule/providers/auth/auth_provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/auth_repository.dart';
import 'package:scheldule/repositories/billing_repository.dart';
import 'package:scheldule/screens/billing/billing_gate.dart';
import 'package:scheldule/screens/billing/billing_page.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

class _BillingApi extends ApiClient {
  @override
  bool get hasSession => true;
  @override
  String get activeStoreId => 'store';
  _BillingApi(superClient)
    : super(baseUrl: 'http://localhost/api/v1', client: superClient);
}

const _plans = [
  {'code': 'monthly', 'months': 1, 'amount_cents': 1000, 'label': '1 μήνας'},
  {'code': 'quarterly', 'months': 3, 'amount_cents': 2400, 'label': '3 μήνες'},
  {'code': 'half_year', 'months': 6, 'amount_cents': 4000, 'label': '6 μήνες'},
  {'code': 'yearly', 'months': 12, 'amount_cents': 5000, 'label': '12 μήνες'},
];
void main() {
  for (final width in [360.0, 768.0, 1280.0]) {
    testWidgets('subscription choices and trial work at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var trialStarted = false;
      final api = _BillingApi(
        MockClient((request) async {
          if (request.url.path.endsWith('/billing/trial')) trialStarted = true;
          final status = {
            'can_manage': true,
            'access_allowed': trialStarted,
            'enabled': true,
            'status': trialStarted ? 'trial' : 'selection_required',
            'trial_available': !trialStarted,
            'checkout_available': false,
            'plans': _plans,
            'payments': [],
          };
          return http.Response(
            jsonEncode({'data': status}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final billing = BillingProvider(
        repository: BillingRepository(apiClient: api),
      );
      final auth = AuthProvider(authRepository: AuthRepository(apiClient: api));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: billing),
            ChangeNotifierProvider.value(value: auth),
          ],
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const BillingGate(child: Text('Application')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BillingPage), findsOneWidget);
      expect(find.text('Application'), findsNothing);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Έναρξη δωρεάν δοκιμής 15 ημερών'),
      );
      await tester.pumpAndSettle();
      expect(trialStarted, isTrue);
      expect(find.text('Application'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      billing.dispose();
      auth.dispose();
    });
  }
  for (final owner in [true, false]) {
    testWidgets(
      'free launch keeps access without payment UI for ${owner ? 'owners' : 'employees'}',
      (tester) async {
        final api = _BillingApi(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'data': {
                  'can_manage': owner,
                  'access_allowed': true,
                  'enabled': false,
                },
              }),
              200,
            ),
          ),
        );
        final billing = BillingProvider(
          repository: BillingRepository(apiClient: api),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: billing,
            child: const MaterialApp(
              home: BillingGate(child: Text('Application')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Application'), findsOneWidget);
        expect(find.text('Συνδρομή'), findsNothing);
        expect(find.byType(BillingPage), findsNothing);
        await tester.pumpWidget(const SizedBox());
        billing.dispose();
      },
    );
  }
}
