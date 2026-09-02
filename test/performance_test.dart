import 'dart:io';

import 'package:bilang/features/count/components/count_row.dart';
import 'package:bilang/features/count/screens/count_screen.dart';
import 'package:bilang/features/counts/components/count_card.dart';
import 'package:bilang/features/counts/screens/counts_screen.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:bilang/types/count_session.dart';
import 'package:bilang/types/scan_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

Future<void> settleThroughStorage(
  WidgetTester tester,
  bool Function() settled,
) async {
  var drained = 0;
  for (var turn = 0; turn < 60; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (settled()) drained++;
    if (drained > 3) return;
  }
}

void main() {
  late Directory dir;
  late LocalStore storage;
  late CountCubit cubit;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_perf_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    cubit = CountCubit(storage);
    await cubit.hydrate();
  });

  tearDown(() async {
    await cubit.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  CountSession bigSession() => CountSession(
    id: 'perf',
    name: 'Yearly stocktake',
    startedAt: DateTime(2026, 8, 31),
    rows: [
      for (var i = 0; i < 500; i++)
        ScanRow(barcode: '4800$i'.padLeft(13, '0'), qty: 1 + i % 24),
    ],
  );

  Widget countHost() => MaterialApp(
    theme: AppTheme.build(),
    home: BlocProvider<CountCubit>.value(
      value: cubit,
      child: Scaffold(
        body: CountScreen(storage: storage, cameraEnabled: false),
      ),
    ),
  );

  testWidgets('a five-hundred-row count renders lazily and scrolls', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await storage.saveSession(bigSession());
      await storage.setActiveCountId('perf');
      await cubit.hydrate();
    });
    await tester.pumpWidget(countHost());
    await tester.pumpAndSettle();

    expect(find.text('500'), findsOneWidget);
    expect(find.text('${cubit.state.active!.units}'), findsOneWidget);
    expect(tester.widgetList(find.byType(CountRow)).length, lessThan(30));

    await tester.fling(find.byType(ListView), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scan into a five-hundred-row count lands at the top', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await storage.saveSession(bigSession());
      await storage.setActiveCountId('perf');
      await cubit.hydrate();
    });
    await tester.pumpWidget(countHost());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9999999999999');
    await tester.runAsync(
      () => tester.testTextInput.receiveAction(TextInputAction.done),
    );
    await tester.pump();
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.length == 501,
    );

    expect(cubit.state.active!.rows.length, 501);
    final top = tester.widget<CountRow>(find.byType(CountRow).first);
    expect(top.row.barcode, '9999999999999');
  });

  testWidgets('sixty saved counts list without loading their rows', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        await storage.saveSession(
          CountSession(
            id: 'count-$i',
            name: 'Count $i',
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
            open: false,
          ),
        );
      }
      await cubit.hydrate();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: BlocProvider<CountCubit>.value(
          value: cubit,
          child: const Scaffold(body: CountsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Count 59'), findsOneWidget);
    expect(tester.widgetList(find.byType(CountCard)).length, lessThan(30));
  });

  test(
    'five hundred scans through the cubit persist and total correctly',
    () async {
      await cubit.startCount('Stress count', at: DateTime(2026, 8, 31));
      for (var i = 0; i < 500; i++) {
        await cubit.recordScan('BC${i % 250}');
      }

      expect(cubit.state.active!.rows.length, 250);
      expect(cubit.state.active!.units, 500);

      final reloaded = await storage.loadSession(cubit.state.active!.id);
      expect(reloaded!.units, 500);
    },
  );
}
