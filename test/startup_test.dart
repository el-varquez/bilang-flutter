import 'dart:io';

import 'package:bilang/features/count/components/count_row.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/shell/app_shell.dart';
import 'package:bilang/shell/splash_gate.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/types/count_session.dart';
import 'package:bilang/types/scan_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

Future<void> settleThroughStorage(WidgetTester tester, Finder target) async {
  for (var turn = 0; turn < 60; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (target.evaluate().isNotEmpty) return;
  }
}

void main() {
  late Directory dir;
  late LocalStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    store = await LocalStore.open();
    await store.hydrate();
  });

  tearDown(() async {
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      return;
    }
  });

  testWidgets('the splash shows first, then the shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashGate(store: store, cameraEnabled: false)),
    );

    expect(find.text('INVENTORY SCANNER'), findsOneWidget);

    await settleThroughStorage(tester, find.text('Count'));

    expect(find.text('INVENTORY SCANNER'), findsNothing);
    expect(find.text('Count'), findsOneWidget);
  });

  testWidgets('the settings tab opens with its cubit wired', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashGate(store: store, cameraEnabled: false)),
    );

    await settleThroughStorage(tester, find.text('Count'));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Small on purpose. Scanning behavior only.'),
      findsOneWidget,
    );
    expect(find.text('Vibrate on scan'), findsOneWidget);
    expect(find.text('Delete all counts on this phone'), findsOneWidget);
  });

  testWidgets('a saved count is on screen after startup', (tester) async {
    final counts = (await tester.runAsync(() async {
      await store.saveSession(
        CountSession(
          id: 's1',
          name: 'Bodega count',
          startedAt: DateTime(2026, 8, 26),
          rows: [const ScanRow(barcode: '4800888812345', qty: 24)],
        ),
      );
      await store.setActiveCountId('s1');
      final hydrated = CountCubit(store);
      await hydrated.hydrate();
      return hydrated;
    }))!;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CountCubit>.value(
          value: counts,
          child: AppShell(storage: store, cameraEnabled: false),
        ),
      ),
    );

    expect(find.text('ITEMS'), findsOneWidget);
    expect(find.text('UNITS COUNTED'), findsOneWidget);
    expect(find.text('4800888812345'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CountRow), matching: find.text('24')),
      findsOneWidget,
    );

    await counts.close();
  });

  test('the cubit hydrates the active session and writes scans through', () async {
    final counts = CountCubit(store);
    await counts.hydrate();

    await counts.startCount('Bodega count', at: DateTime(2026, 8, 26));
    await counts.recordScan('4800888812345', name: 'Kopiko Blanca Twin');
    await counts.recordScan('4800888812345');
    await counts.close();
    await store.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = CountCubit(reopened);
    await revived.hydrate();

    expect(revived.state.active, isNotNull);
    expect(revived.state.active!.name, 'Bodega count');
    expect(revived.state.active!.units, 2);
    expect(revived.state.summaries.single.unitCount, 2);

    await revived.close();
  });
}
