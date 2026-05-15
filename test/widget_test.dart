import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:agenda_academica/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('home screen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const AgendaAcademicaApp());
    await tester.pump();

    expect(find.text('Agenda Académica'), findsOneWidget);
  });

  testWidgets('FAB with Nuevo label is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const AgendaAcademicaApp());
    await tester.pump();

    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
