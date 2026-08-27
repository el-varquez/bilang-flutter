import 'dart:io';

import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

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
    await cubit.startCount('Bodega count', at: DateTime(2026, 8, 26));
  });

  tearDown(() async {
    await cubit.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a scan creates a row, a repeat scan increments it', () async {
    await cubit.recordScan('4800888812345', name: 'Kopiko Blanca Twin');
    await cubit.recordScan('4800888812345');

    final session = cubit.state.active!;
    expect(session.rows.length, 1);
    expect(session.rows.single.qty, 2);
    expect(session.rows.single.name, 'Kopiko Blanca Twin');
    expect(session.units, 2);
  });

  test('emitting a scan produces a new state object', () async {
    final before = cubit.state;
    await cubit.recordScan('111');

    expect(cubit.state, isNot(before));
    expect(before.active!.rows, isEmpty);
  });

  test('batch scan adds the configured units per scan', () async {
    await cubit.recordScan('4800194115817', units: 10);
    await cubit.recordScan('4800194115817', units: 10);

    expect(cubit.state.active!.units, 20);
  });

  test('starting a new count closes the previous one', () async {
    await cubit.recordScan('4800888812345');
    await cubit.startCount('Front shelf count', at: DateTime(2026, 8, 27));

    expect(cubit.state.summaries.length, 2);
    expect(cubit.state.active!.name, 'Front shelf count');
    expect(cubit.state.summaries.last.open, isFalse);
  });

  test('a closed count refuses new scans', () async {
    await cubit.startCount('Second count', at: DateTime(2026, 8, 27));
    final closed = cubit.state.summaries.last;
    await cubit.openCount(closed.id);
    await cubit.recordScan('4800888812345');

    expect(cubit.state.active!.open, isFalse);
    expect(cubit.state.active!.rows, isEmpty);
  });

  test('setting a quantity to zero removes the row', () async {
    await cubit.recordScan('111');
    await cubit.recordScan('222');
    await cubit.setQuantity('111', 7);
    expect(cubit.state.active!.rows.first.qty, 7);

    await cubit.setQuantity('111', 0);
    expect(cubit.state.active!.rows.map((r) => r.barcode).toList(), ['222']);
  });

  test('mutations survive a reopen', () async {
    await cubit.recordScan('4800888812345', units: 3);
    await cubit.close();
    await storage.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = CountCubit(reopened);
    await revived.hydrate();

    expect(revived.state.active!.units, 3);
    expect(revived.state.summaries.single.unitCount, 3);
    await revived.close();
  });

  test('naming a row keeps its barcode and quantity', () async {
    await cubit.recordScan('4800888812345', units: 3);
    await cubit.nameRow('4800888812345', 'Kopiko Blanca Twin');

    final row = cubit.state.active!.rows.single;
    expect(row.name, 'Kopiko Blanca Twin');
    expect(row.barcode, '4800888812345');
    expect(row.qty, 3);
  });

  test('deleting a count removes it from both boxes', () async {
    await cubit.startCount('Second count', at: DateTime(2026, 8, 27));
    final older = cubit.state.summaries.last;

    await cubit.deleteCount(older.id);

    expect(cubit.state.summaries.single.name, 'Second count');
    expect(await storage.loadSession(older.id), isNull);
  });

  test('deleting the active count leaves nothing open', () async {
    await cubit.deleteCount(cubit.state.active!.id);

    expect(cubit.state.active, isNull);
    expect(cubit.state.summaries, isEmpty);
    expect(storage.activeCountId, isNull);
  });

  test('deleting another count leaves the active one alone', () async {
    await cubit.startCount('Second count', at: DateTime(2026, 8, 27));

    await cubit.deleteCount(cubit.state.summaries.last.id);

    expect(cubit.state.active!.name, 'Second count');
    expect(storage.activeCountId, cubit.state.active!.id);
  });

  test('a deleted count stays gone after a reopen', () async {
    await cubit.startCount('Second count', at: DateTime(2026, 8, 27));
    await cubit.deleteCount(cubit.state.summaries.last.id);
    await cubit.close();
    await storage.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = CountCubit(reopened);
    await revived.hydrate();

    expect(revived.state.summaries.single.name, 'Second count');
    await revived.close();
  });

  test('a blank name clears back to unnamed and survives a reopen', () async {
    await cubit.recordScan('4800888812345');
    await cubit.nameRow('4800888812345', 'Kopiko');
    await cubit.nameRow('4800888812345', null);
    await cubit.close();
    await storage.close();

    final reopened = await LocalStore.open();
    await reopened.hydrate();
    final revived = CountCubit(reopened);
    await revived.hydrate();

    expect(revived.state.active!.rows.single.name, isNull);
    await revived.close();
  });
}
