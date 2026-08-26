import 'package:bilang/store/count_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CountStore store;

  setUp(() {
    store = CountStore();
    store.startCount('Bodega count', at: DateTime(2026, 8, 26));
  });

  test('a scan creates a row, a repeat scan increments it', () {
    store.recordScan('4800888812345', name: 'Kopiko Blanca Twin');
    store.recordScan('4800888812345');

    final session = store.active!;
    expect(session.rows.length, 1);
    expect(session.rows.single.qty, 2);
    expect(session.rows.single.name, 'Kopiko Blanca Twin');
    expect(session.units, 2);
  });

  test('batch scan adds the configured units per scan', () {
    store.recordScan('4800194115817', units: 10);
    store.recordScan('4800194115817', units: 10);

    expect(store.active!.units, 20);
  });

  test('undo reverses exactly one scan, batch included', () {
    store.recordScan('4800194115817', units: 10);
    store.recordScan('4800194115817', units: 10);
    store.undoLastScan(units: 10);

    expect(store.active!.units, 10);
    expect(store.canUndo, isTrue);

    store.undoLastScan(units: 10);
    expect(store.active!.rows, isEmpty);
    expect(store.canUndo, isFalse);
  });

  test('starting a new count closes the previous one', () {
    store.recordScan('4800888812345');
    store.startCount('Front shelf count', at: DateTime(2026, 8, 27));

    expect(store.sessions.length, 2);
    expect(store.active!.name, 'Front shelf count');
    expect(store.sessions.last.open, isFalse);
  });

  test('a closed count refuses new scans', () {
    store.startCount('Second count', at: DateTime(2026, 8, 27));
    final closed = store.sessions.last;
    store.openCount(closed.id);
    store.recordScan('4800888812345');

    expect(closed.rows, isEmpty);
  });
}
