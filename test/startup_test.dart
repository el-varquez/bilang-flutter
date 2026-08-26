import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:bilang/shell/app_shell.dart';
import 'package:bilang/shell/splash_gate.dart';
import 'package:bilang/store/count_store.dart';
import 'package:bilang/types/count_session.dart';
import 'package:bilang/types/scan_row.dart';
import 'package:flutter/material.dart';
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
    await tester.pumpWidget(MaterialApp(home: SplashGate(store: store)));

    expect(find.text('Inventory Scanner'), findsOneWidget);

    await settleThroughStorage(tester, find.text('Count'));

    expect(find.text('Inventory Scanner'), findsNothing);
    expect(find.text('Count'), findsOneWidget);
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
      final hydrated = CountStore(store);
      await hydrated.hydrate();
      return hydrated;
    }))!;

    await tester.pumpWidget(MaterialApp(home: AppShell(store: counts)));

    expect(find.textContaining('Bodega count'), findsOneWidget);
    expect(find.textContaining('24 units'), findsOneWidget);
  });

  test('the store hydrates the active session and writes scans through', () async {
    final counts = CountStore(store);
    await counts.hydrate();

    await counts.startCount('Bodega count', at: DateTime(2026, 8, 26));
    await counts.recordScan('4800888812345', name: 'Kopiko Blanca Twin');
    await counts.recordScan('4800888812345');
    await store.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = CountStore(reopened);
    await revived.hydrate();

    expect(revived.active, isNotNull);
    expect(revived.active!.name, 'Bodega count');
    expect(revived.active!.units, 2);
    expect(revived.summaries.single.unitCount, 2);
  });
}
