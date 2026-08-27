import 'dart:io';

import 'package:bilang/components/app_button.dart';
import 'package:bilang/features/count/components/count_row.dart';
import 'package:bilang/features/count/screens/count_screen.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: Scaffold(body: CountScreen(storage: storage, cameraEnabled: false)),
    ),
  );

  Future<void> tapLive(WidgetTester tester, Finder target) async {
    await tester.runAsync(() => tester.tap(target));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester, String barcode) async {
    await tester.enterText(find.byType(TextField), barcode);
    await tester.runAsync(
      () => tester.testTextInput.receiveAction(TextInputAction.done),
    );
    await tester.pump();
  }

  testWidgets('with no count open the screen invites one', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('START A COUNT'), findsOneWidget);
  });

  testWidgets('typing a barcode adds a row', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await submit(tester, '4800888812345');
    await settleThroughStorage(tester, () => cubit.state.active!.rows.isNotEmpty);

    expect(cubit.state.active!.rows.single.barcode, '4800888812345');
    expect(cubit.state.active!.units, 1);
  });

  testWidgets('the field clears itself for the next scan', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await submit(tester, '4800888812345');
    await settleThroughStorage(tester, () => cubit.state.active!.rows.isNotEmpty);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('batch scan multiplies a typed entry', (tester) async {
    await tester.runAsync(() async {
      await storage.setBatchSize(10);
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await submit(tester, '4800194115817');
    await settleThroughStorage(tester, () => cubit.state.active!.units == 10);

    expect(cubit.state.active!.units, 10);
  });

  testWidgets('blank input is ignored', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await submit(tester, '   ');
    await tester.pumpAndSettle();

    expect(cubit.state.active!.rows, isEmpty);
  });

  testWidgets('the viewfinder starts idle and invites a press', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('PRESS SCAN TO READ'), findsOneWidget);
    expect(find.text('SCANNING…'), findsNothing);
    expect(find.widgetWithText(AppButton, 'SCAN'), findsOneWidget);
  });

  testWidgets('the stepper adjusts a row', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345', units: 2);
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('+'));
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.single.qty == 3,
    );
    expect(cubit.state.active!.rows.single.qty, 3);

    await tapLive(tester, find.text('−'));
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.single.qty == 2,
    );
    expect(cubit.state.active!.rows.single.qty, 2);
  });

  testWidgets('stepping down at one keeps the row', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345');
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('−'));
    await settleThroughStorage(tester, () => cubit.state.active != null);

    expect(cubit.state.active!.rows.single.qty, 1);
  });

  testWidgets('tapping the quantity types an exact number', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345');
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(
      tester,
      find.descendant(of: find.byType(CountRow), matching: find.text('1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '24');
    await tapLive(tester, find.text('SET'));
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.single.qty == 24,
    );

    expect(cubit.state.active!.rows.single.qty, 24);
  });

  testWidgets('typing zero removes the row', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345');
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(
      tester,
      find.descendant(of: find.byType(CountRow), matching: find.text('1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0');
    await tapLive(tester, find.text('SET'));
    await settleThroughStorage(tester, () => cubit.state.active!.rows.isEmpty);

    expect(cubit.state.active!.rows, isEmpty);
  });

  testWidgets('an unnamed row invites a name and takes one', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345');
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('tap to name'), findsOneWidget);

    await tapLive(tester, find.text('tap to name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Kopiko Blanca Twin');
    await tapLive(tester, find.text('SAVE'));
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.single.name != null,
    );

    expect(cubit.state.active!.rows.single.name, 'Kopiko Blanca Twin');
  });

  testWidgets('a row swipes onto a delete panel', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Bodega count', at: DateTime(2026, 8, 27));
      await cubit.recordScan('4800888812345');
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CountRow)),
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

    expect(cubit.state.active!.rows.single.barcode, '4800888812345');
  });

  testWidgets('starting a count here asks for a name too', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('START A COUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Start a new count'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bodega count');
    await tapLive(tester, find.text('START'));
    await settleThroughStorage(tester, () => cubit.state.active != null);

    expect(cubit.state.active!.name, 'Bodega count');
  });

  testWidgets('cancelling the name starts no count', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('START A COUNT'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(cubit.state.active, isNull);
    expect(find.text('No count open'), findsOneWidget);
  });

  testWidgets('the field does not grab focus on arrival', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isFalse);
    expect(field.focusNode!.hasFocus, isFalse);
  });

  testWidgets('a wedge burst rings without touching the field', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4, character: '4');
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8, character: '8');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    });
    await settleThroughStorage(
      tester,
      () => cubit.state.active!.rows.isNotEmpty,
    );

    expect(cubit.state.active!.rows.single.barcode, '48');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('a wedge burst is ignored while the field has focus', (
    tester,
  ) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4, character: '4');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    });
    await tester.pumpAndSettle();

    expect(cubit.state.active!.rows, isEmpty);
  });

  testWidgets('a wedge burst is ignored when the count is closed', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await cubit.startCount('Older count', at: DateTime(2026, 8, 26));
      await cubit.startCount('Newer count', at: DateTime(2026, 8, 27));
      await cubit.openCount(cubit.state.summaries.last.id);
    });
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4, character: '4');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    });
    await tester.pumpAndSettle();

    expect(cubit.state.active!.rows, isEmpty);
  });

  testWidgets('a closed count cannot be scanned into', (tester) async {
    await tester.runAsync(() async {
      await cubit.startCount('Older count', at: DateTime(2026, 8, 26));
      await cubit.startCount('Newer count', at: DateTime(2026, 8, 27));
      await cubit.openCount(cubit.state.summaries.last.id);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('This count is done'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
  });

  testWidgets('an open count can be scanned into', (tester) async {
    await tester.runAsync(
      () => cubit.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('This count is done'), findsNothing);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isTrue);
  });
}
