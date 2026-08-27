import 'dart:io';

import 'package:bilang/features/count/screens/count_screen.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
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
      child: Scaffold(body: CountScreen(storage: storage, cameraEnabled: false)),
    ),
  );

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
}
