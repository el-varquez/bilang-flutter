import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;
  late LocalStore storage;
  late CountStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    store = CountStore(storage);
    await store.hydrate();
    await store.startCount('Bodega count', at: DateTime(2026, 8, 26));
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a scan creates a row, a repeat scan increments it', () async {
    await store.recordScan('4800888812345', name: 'Kopiko Blanca Twin');
    await store.recordScan('4800888812345');

    final session = store.active!;
    expect(session.rows.length, 1);
    expect(session.rows.single.qty, 2);
    expect(session.rows.single.name, 'Kopiko Blanca Twin');
    expect(session.units, 2);
  });

  test('batch scan adds the configured units per scan', () async {
    await store.recordScan('4800194115817', units: 10);
    await store.recordScan('4800194115817', units: 10);

    expect(store.active!.units, 20);
  });

  test('undo reverses exactly one scan, batch included', () async {
    await store.recordScan('4800194115817', units: 10);
    await store.recordScan('4800194115817', units: 10);
    await store.undoLastScan(units: 10);

    expect(store.active!.units, 10);
    expect(store.canUndo, isTrue);

    await store.undoLastScan(units: 10);
    expect(store.active!.rows, isEmpty);
    expect(store.canUndo, isFalse);
  });

  test('starting a new count closes the previous one', () async {
    await store.recordScan('4800888812345');
    await store.startCount('Front shelf count', at: DateTime(2026, 8, 27));

    expect(store.summaries.length, 2);
    expect(store.active!.name, 'Front shelf count');
    expect(store.summaries.last.open, isFalse);
  });

  test('a closed count refuses new scans', () async {
    await store.startCount('Second count', at: DateTime(2026, 8, 27));
    final closed = store.summaries.last;
    await store.openCount(closed.id);
    await store.recordScan('4800888812345');

    expect(store.active!.open, isFalse);
    expect(store.active!.rows, isEmpty);
  });
}
