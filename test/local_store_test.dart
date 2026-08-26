import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;
  late LocalStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    store = await LocalStore.open();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a fresh install carries the designed defaults', () {
    expect(store.vibrate, isTrue);
    expect(store.beep, isFalse);
    expect(store.batchSize, 0);
    expect(store.liveUrl, '');
    expect(store.activeCountId, isNull);
  });

  test('the schema version is stamped on first open', () {
    expect(store.schemaVersion, LocalStore.currentSchemaVersion);
  });

  test('settings survive a close and reopen', () async {
    await store.setVibrate(false);
    await store.setBeep(true);
    await store.setBatchSize(10);
    await store.setLiveUrl('http://192.168.1.4:5103/api/scans');
    await store.setActiveCountId('s1');
    await store.close();

    final reopened = await LocalStore.open();
    expect(reopened.vibrate, isFalse);
    expect(reopened.beep, isTrue);
    expect(reopened.batchSize, 10);
    expect(reopened.liveUrl, 'http://192.168.1.4:5103/api/scans');
    expect(reopened.activeCountId, 's1');
  });

  test('a corrupt box file degrades to empty instead of throwing', () async {
    await store.close();
    final corrupt = File('${dir.path}/${LocalStore.settingsBoxName}.hive');
    await corrupt.writeAsBytes(List<int>.filled(512, 0x7f));

    final recovered = await LocalStore.open();
    expect(recovered.vibrate, isTrue);
  });
}
