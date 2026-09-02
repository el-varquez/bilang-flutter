import 'dart:io';
import 'dart:typed_data';

import 'package:bilang/services/file_delivery.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/shell/app_shell.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

class StubDelivery implements FileDelivery {
  @override
  Future<ShareOutcome> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async => ShareOutcome.shared;

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async => true;
}

void main() {
  late Directory dir;
  late LocalStore storage;
  late CountCubit counts;

  Widget shell(CountCubit cubit) => MaterialApp(
    home: BlocProvider<CountCubit>.value(
      value: cubit,
      child: AppShell(
        storage: storage,
        delivery: StubDelivery(),
        cameraEnabled: false,
      ),
    ),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    counts = CountCubit(storage);
    await counts.hydrate();
  });

  tearDown(() async {
    await counts.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('the shell renders the four tabs and opens the count screen', (
    tester,
  ) async {
    await tester.pumpWidget(shell(counts));

    expect(find.text('Count'), findsOneWidget);
    expect(find.text('Saved Counts'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('No count open'), findsOneWidget);
  });

  testWidgets('tapping a tab switches the screen', (tester) async {
    await tester.pumpWidget(shell(counts));

    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No counts yet'), findsOneWidget);
  });
}
