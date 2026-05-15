import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agenda_academica/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App integration tests', () {
    testWidgets('app launches and shows home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Agenda Académica'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('sync button is present in AppBar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.byIcon(Icons.sync).evaluate().isNotEmpty ||
            find.byIcon(Icons.sync_problem).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('can navigate to create event form', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo evento'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('form shows validation errors when submitted empty',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese el título del evento'), findsOneWidget);
      expect(find.text('Ingrese la materia'), findsOneWidget);
    });

    testWidgets('can cancel from event form and return to home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo evento'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Agenda Académica'), findsOneWidget);
    });

    testWidgets('can create an event and it appears in the list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Prueba de integración',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Flutter Testing',
      );

      // Select date
      await tester.tap(find.text('Seleccionar fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select time
      await tester.tap(find.text('Seleccionar hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Prueba de integración'), findsOneWidget);
    });

    testWidgets('help screen is accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.help_outline).first);
      await tester.pumpAndSettle();

      // Help screen should have opened (check for back button or content)
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
