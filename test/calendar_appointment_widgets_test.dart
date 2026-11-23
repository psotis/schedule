import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheldule/screens/calendar/widgets/appointment_summary_dialog.dart';
import 'package:scheldule/screens/calendar/widgets/calendar_appointment_tile.dart';
import 'package:scheldule/styling/themes/app_theme.dart';

void main() {
  final start = DateTime(2026, 11, 23, 10);
  for (final brightness in Brightness.values) {
    for (final size in [
      const Size(65, 90),
      const Size(120, 60),
      const Size(200, 22),
    ]) {
      testWidgets('customer name wraps safely at $size in $brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: CalendarAppointmentTile(
                    customer: 'ΚΩΝΣΤΑΝΤΙΝΟΣ ΓΕΩΡΓΟΠΟΥΛΟΣ',
                    start: start,
                    end: start.add(const Duration(hours: 1)),
                    background: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );
        final text = tester.widget<Text>(
          find.text('ΚΩΝΣΤΑΝΤΙΝΟΣ ΓΕΩΡΓΟΠΟΥΛΟΣ'),
        );
        expect(text.softWrap, isTrue);
        if (size.height > 30) expect(text.maxLines, greaterThan(1));
        expect(find.byType(Tooltip), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  Future<void> open(
    WidgetTester tester,
    Future<void> Function() onDelete, {
    String employee = 'Μαρία Παππά',
    String station = 'Αίθουσα 2',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => AppointmentSummaryDialog(
                  customer: 'Γιώργος Παππάς',
                  start: start,
                  end: start.add(const Duration(minutes: 45)),
                  employee: employee,
                  station: station,
                  onDelete: onDelete,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('summary shows booking details and close never deletes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deletes = 0;
    await open(tester, () async {
      deletes++;
    });
    for (final text in [
      'Γιώργος Παππάς',
      '23/11/2026',
      '10:00 – 10:45',
      'Μαρία Παππά',
      'Αίθουσα 2',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    await tester.tap(find.text('Κλείσιμο'));
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentSummaryDialog), findsNothing);
    expect(deletes, 0);
  });

  testWidgets('delete waits for success and prevents repeated requests', (
    tester,
  ) async {
    final completion = Completer<void>();
    var deletes = 0;
    await open(
      tester,
      () {
        deletes++;
        return completion.future;
      },
      employee: '',
      station: '',
    );
    expect(find.text('Χωρίς ανάθεση'), findsOneWidget);
    expect(find.text('Δεν έχει οριστεί'), findsOneWidget);
    await tester.tap(find.text('Διαγραφή'));
    await tester.pump();
    expect(find.byType(AppointmentSummaryDialog), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    completion.complete();
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(find.byType(AppointmentSummaryDialog), findsNothing);
  });

  testWidgets('failed deletion leaves summary open with an error', (
    tester,
  ) async {
    await open(tester, () async {
      throw StateError('offline');
    });
    await tester.tap(find.text('Διαγραφή'));
    await tester.pumpAndSettle();
    expect(find.text('Η διαγραφή απέτυχε. Δοκιμάστε ξανά.'), findsOneWidget);
    expect(find.text('Γιώργος Παππάς'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });
}
