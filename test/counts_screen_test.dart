import 'dart:io';

import 'package:bilang/features/counts/components/count_card.dart';
import 'package:bilang/features/counts/components/delete_count_dialog.dart';
import 'package:bilang/features/counts/screens/counts_screen.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:bilang/types/count_summary.dart';
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
    dir = await Directory.systemTemp.createTemp('bilang_test_');
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

  Widget host() => MaterialApp(
    theme: AppTheme.build(),
    home: BlocProvider<CountCubit>.value(
      value: cubit,
      child: const Scaffold(body: CountsScreen()),
    ),
  );

  Future<void> tapLive(WidgetTester tester, Finder target) async {
    await tester.runAsync(() => tester.tap(target));
    await tester.pump();
  }

  testWidgets('with nothing counted it explains itself', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Saved Counts'), findsOneWidget);
    expect(
      find.text(
        'One count per stocktake. Everything is saved on this phone as you scan.',
      ),
      findsOneWidget,
    );
    expect(find.text('Start a new count'), findsOneWidget);
  });

  testWidgets('a count shows its name, status and totals', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345', units: 24);
      await cubit.recordScan('4800194115817', units: 6);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Bodega count'), findsOneWidget);
    expect(find.text('● Open'), findsOneWidget);
    expect(find.text('Aug 27 · 2 items · 30 units'), findsOneWidget);
  });

  testWidgets('a superseded count reads as done', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Older count', at: DateTime(2026, 8, 26));
      await cubit.startCount('Newer count', at: DateTime(2026, 8, 27));
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('● Open'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('newest first', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Older count', at: DateTime(2026, 8, 26));
      await cubit.startCount('Newer count', at: DateTime(2026, 8, 27));
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final newer = tester.getTopLeft(find.text('Newer count'));
    final older = tester.getTopLeft(find.text('Older count'));
    expect(newer.dy, lessThan(older.dy));
  });

  testWidgets('tapping a count makes it the active one', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Older count', at: DateTime(2026, 8, 26));
      await cubit.startCount('Newer count', at: DateTime(2026, 8, 27));
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Older count'));
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.name == 'Older count',
    );

    expect(cubit.state.active!.name, 'Older count');
  });

  testWidgets('starting a count asks for a name and opens it', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Start a new count'));
    await tester.pumpAndSettle();

    expect(find.text('Count name'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    await tester.enterText(find.byType(TextField), 'Bodega count');
    await tapLive(tester, find.text('START'));
    await settleThroughStorage(tester, () => cubit.state.active != null);

    expect(cubit.state.active!.name, 'Bodega count');
    expect(cubit.state.active!.open, isTrue);
  });

  testWidgets('cancelling starts nothing', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Start a new count'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(cubit.state.active, isNull);
    expect(cubit.state.summaries, isEmpty);
  });

  testWidgets('a blank name starts nothing', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Start a new count'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tapLive(tester, find.text('START'));
    await tester.pumpAndSettle();

    expect(cubit.state.active, isNull);
  });

  testWidgets('starting a count closes the one before it', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Older count', at: DateTime(2026, 8, 26)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Start a new count'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Newer count');
    await tapLive(tester, find.text('START'));
    await settleThroughStorage(
      tester,
      () => cubit.state.summaries.length == 2,
    );

    expect(cubit.state.active!.name, 'Newer count');
    expect(cubit.state.summaries.length, 2);
    expect(cubit.state.summaries.last.open, isFalse);
  });

  testWidgets('a count swipes onto a delete panel', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CountCard)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(find.text('Delete'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(cubit.state.summaries.single.name, 'Bodega count');
  });

  testWidgets('swiping a count away asks before deleting', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.runAsync(
      () => tester.drag(find.byType(CountCard), const Offset(-500, 0)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure to permanently delete this count?'),
      findsOneWidget,
    );
    expect(find.text('DELETE'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
  });

  testWidgets('the alert names the count and answers both ways', (
    tester,
  ) async {
    final summary = CountSummary(
      id: 'c1',
      name: 'Bodega count',
      startedAt: DateTime(2026, 8, 27),
      open: true,
      itemCount: 2,
      unitCount: 30,
    );
    bool? answer;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  answer = await confirmDeleteCount(context, summary),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Delete count'), findsOneWidget);
    expect(find.text('Bodega count'), findsOneWidget);
    expect(find.text('Aug 27 · 2 items · 30 units'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });
}
