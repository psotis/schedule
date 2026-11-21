import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/screens/responsive_ui/settings/messaging_settings.dart';
import 'package:scheldule/utils/custom_text_form.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('iSMS.gr setup uses its own fields at $width $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, dynamic>? saved;
        final api = ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            if (request.method == 'PUT') {
              saved = jsonDecode(request.body) as Map<String, dynamic>;
            }
            return http.Response(
              jsonEncode({
                'data': {
                  'provider': 'twilio',
                  'encryption_ready': true,
                  'configured': false,
                  'enabled': false,
                  'reminder_hours': 24,
                },
              }),
              200,
            );
          }),
        );
        await tester.pumpWidget(
          Provider.value(
            value: api,
            child: MaterialApp(
              theme: buildAppTheme(brightness),
              home: const Scaffold(body: MessagingSettings()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('iSMS.gr').last);
        await tester.pumpAndSettle();
        expect(find.text('SMS υπενθυμίσεις με iSMS.gr'), findsOneWidget);
        expect(find.text('Δημιουργία λογαριασμού iSMS.gr'), findsOneWidget);
        await tester.scrollUntilVisible(find.byType(Form), 400);
        final fields = find.byType(CustomTextForm);
        expect(fields, findsNWidgets(2));
        expect(
          tester.widget<CustomTextForm>(fields.at(0)).labelText,
          'iSMS.gr API Key',
        );
        expect(tester.widget<CustomTextForm>(fields.at(0)).obscureText, true);
        await tester.enterText(
          find.descendant(
            of: fields.at(0),
            matching: find.byType(TextFormField),
          ),
          'fixture-isms-private-key',
        );
        await tester.enterText(
          find.descendant(
            of: fields.at(1),
            matching: find.byType(TextFormField),
          ),
          'MY.SHOP',
        );
        final save = find.widgetWithText(FilledButton, 'Αποθήκευση ρυθμίσεων');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(saved, {
          'provider': 'isms',
          'api_token': 'fixture-isms-private-key',
          'sender': 'MY.SHOP',
          'enabled': false,
          'reminder_hours': 24,
        });
        expect(
          tester.widget<CustomTextForm>(fields.at(0)).controller!.text,
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'existing iSMS.gr key stays hidden and is preserved without resubmission',
    (tester) async {
      Map<String, dynamic>? saved;
      final api = ApiClient(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.method == 'PUT') {
            saved = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return http.Response(
            jsonEncode({
              'data': {
                'provider': 'isms',
                'encryption_ready': true,
                'configured': true,
                'has_api_token': true,
                'sender': 'MY.SHOP',
                'enabled': true,
                'reminder_hours': 24,
              },
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        Provider.value(
          value: api,
          child: MaterialApp(home: const Scaffold(body: MessagingSettings())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(Form), 400);
      final secret = tester.widget<CustomTextForm>(
        find.byType(CustomTextForm).first,
      );
      expect(secret.controller!.text, isEmpty);
      final save = find.widgetWithText(FilledButton, 'Αποθήκευση ρυθμίσεων');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved?['provider'], 'isms');
      expect(saved?['enabled'], true);
      expect(saved!.containsKey('api_token'), false);
      expect(tester.takeException(), isNull);
    },
  );
}
