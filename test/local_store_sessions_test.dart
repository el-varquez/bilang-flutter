import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:bilang/types/count_session.dart';
import 'package:bilang/types/scan_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

CountSession sessionWith(String id, String name, List<ScanRow> rows) =>
    CountSession(
      id: id,
      name: name,
      startedAt: DateTime(2026, 8, 26, 21, 30),
      rows: rows,
    );

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
    await dir.delete(recursive: true);
  });

  test('a session round-trips with its rows intact', () async {
    await store.saveSession(
      sessionWith('s1', 'Bodega count', [
        const ScanRow(
          barcode: '4800888812345',
          name: 'Kopiko Blanca Twin',
          qty: 24,
        ),
        const ScanRow(barcode: '4800361413480', qty: 3),
      ]),
    );
    await store.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final loaded = await reopened.loadSession('s1');

    expect(loaded, isNotNull);
    expect(loaded!.name, 'Bodega count');
    expect(loaded.startedAt, DateTime(2026, 8, 26, 21, 30));
    expect(loaded.open, isTrue);
    expect(loaded.rows.length, 2);
    expect(loaded.rows.first.barcode, '4800888812345');
    expect(loaded.rows.first.name, 'Kopiko Blanca Twin');
    expect(loaded.rows.first.qty, 24);
    expect(loaded.rows.last.name, isNull);
    expect(loaded.units, 27);
  });

  test('summaries carry counts without loading rows, newest first', () async {
    await store.saveSession(
      sessionWith('s1', 'Older count', [const ScanRow(barcode: '111', qty: 2)]),
    );
    await store.saveSession(
      CountSession(
        id: 's2',
        name: 'Newer count',
        startedAt: DateTime(2026, 8, 27),
        rows: [const ScanRow(barcode: '222', qty: 5)],
      ),
    );

    final summaries = store.summaries();
    expect(summaries.map((s) => s.id).toList(), ['s2', 's1']);
    expect(summaries.first.name, 'Newer count');
    expect(summaries.first.itemCount, 1);
    expect(summaries.first.unitCount, 5);
    expect(summaries.last.unitCount, 2);
  });

  test('saving the same session again replaces it rather than duplicating', () async {
    await store.saveSession(
      sessionWith('s1', 'Bodega count', [const ScanRow(barcode: '111', qty: 1)]),
    );
    await store.saveSession(
      sessionWith('s1', 'Bodega count', [const ScanRow(barcode: '111', qty: 9)]),
    );

    expect(store.summaries().length, 1);
    expect(store.summaries().single.unitCount, 9);
    expect((await store.loadSession('s1'))!.rows.single.qty, 9);
  });

  test('deleting a session removes it from both boxes', () async {
    await store.saveSession(sessionWith('s1', 'One', const []));
    await store.saveSession(sessionWith('s2', 'Two', const []));

    await store.deleteSession('s1');

    expect(store.summaries().map((s) => s.id).toList(), ['s2']);
    expect(await store.loadSession('s1'), isNull);
  });

  test('deleting everything empties both boxes', () async {
    await store.saveSession(sessionWith('s1', 'One', const []));
    await store.saveSession(sessionWith('s2', 'Two', const []));

    await store.deleteAllCounts();

    expect(store.summaries(), isEmpty);
    expect(await store.loadSession('s2'), isNull);
  });

  test('an unknown id loads as null', () async {
    expect(await store.loadSession('nope'), isNull);
  });

  test('sessions and rows compare by value', () {
    const rowA = ScanRow(barcode: '111', name: 'Kopiko', qty: 2);
    const rowB = ScanRow(barcode: '111', name: 'Kopiko', qty: 2);
    expect(rowA, rowB);

    final sessionA = sessionWith('s1', 'Bodega count', const [rowA]);
    final sessionB = sessionWith('s1', 'Bodega count', const [rowB]);
    expect(sessionA, sessionB);

    expect(sessionA.copyWith(rows: const []), isNot(sessionA));
    expect(sessionA.copyWith(open: false).open, isFalse);
    expect(sessionA.copyWith(name: 'Renamed').name, 'Renamed');
    expect(sessionA.copyWith(name: 'Renamed').rows, sessionA.rows);
  });
}
