import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/settings_cubit.dart';
import 'package:bilang/types/count_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

class CountSessionStub {
  static CountSession build() => CountSession(
    id: 's1',
    name: 'Bodega count',
    startedAt: DateTime(2026, 8, 27),
  );
}

void main() {
  late Directory dir;
  late LocalStore storage;
  late SettingsCubit cubit;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    cubit = SettingsCubit(storage)..hydrate();
  });

  tearDown(() async {
    await cubit.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('it starts from the stored defaults', () {
    expect(cubit.state.vibrate, isTrue);
    expect(cubit.state.beep, isFalse);
    expect(cubit.state.batchSize, 0);
    expect(cubit.state.batchOn, isFalse);
    expect(cubit.state.liveUrl, '');
    expect(cubit.state.liveOn, isFalse);
  });

  test('each toggle emits a new state and writes through', () async {
    final before = cubit.state;
    await cubit.setVibrate(false);
    await cubit.setBeep(true);

    expect(cubit.state, isNot(before));
    expect(storage.vibrate, isFalse);
    expect(storage.beep, isTrue);
  });

  test('batch scan is on only above one', () async {
    await cubit.setBatchSize(10);
    expect(cubit.state.batchOn, isTrue);
    expect(storage.batchSize, 10);

    await cubit.setBatchSize(0);
    expect(cubit.state.batchOn, isFalse);
  });

  test('the live connection is on only with a url', () async {
    await cubit.setLiveUrl('http://192.168.1.4:5103/api/scans');
    expect(cubit.state.liveOn, isTrue);

    await cubit.setLiveUrl('');
    expect(cubit.state.liveOn, isFalse);
    expect(storage.liveUrl, '');
  });

  test('settings survive a reopen', () async {
    await cubit.setBatchSize(24);
    await cubit.setLiveUrl('http://example.test/scans');
    await cubit.close();
    await storage.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = SettingsCubit(reopened)..hydrate();

    expect(revived.state.batchSize, 24);
    expect(revived.state.liveUrl, 'http://example.test/scans');
    await revived.close();
  });

  test('deleting every count empties storage', () async {
    await storage.saveSession(CountSessionStub.build());
    expect(storage.summaries(), isNotEmpty);

    await cubit.deleteAllCounts();

    expect(storage.summaries(), isEmpty);
  });
}
