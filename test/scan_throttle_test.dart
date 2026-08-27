import 'package:bilang/features/count/services/scan_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ScanThrottle throttle;
  final start = DateTime(2026, 8, 27, 21, 0, 0);

  setUp(() {
    throttle = ScanThrottle(window: const Duration(milliseconds: 1200));
  });

  test('the first sighting of a barcode counts', () {
    expect(throttle.allow('4800888812345', start), isTrue);
  });

  test('an immediate repeat of the same barcode does not count', () {
    throttle.allow('4800888812345', start);

    expect(
      throttle.allow('4800888812345', start.add(const Duration(milliseconds: 40))),
      isFalse,
    );
  });

  test('a barcode held in frame counts once, however long it is held', () {
    expect(throttle.allow('4800888812345', start), isTrue);

    var now = start;
    for (var i = 0; i < 200; i++) {
      now = now.add(const Duration(milliseconds: 33));
      expect(throttle.allow('4800888812345', now), isFalse);
    }
  });

  test('lifting the barcode away for longer than the window counts again', () {
    throttle.allow('4800888812345', start);

    expect(
      throttle.allow('4800888812345', start.add(const Duration(milliseconds: 1500))),
      isTrue,
    );
  });

  test('a different barcode counts immediately', () {
    throttle.allow('4800888812345', start);

    expect(
      throttle.allow('4800194115817', start.add(const Duration(milliseconds: 40))),
      isTrue,
    );
  });

  test('reset forgets the last sighting', () {
    throttle.allow('4800888812345', start);
    throttle.reset();

    expect(
      throttle.allow('4800888812345', start.add(const Duration(milliseconds: 40))),
      isTrue,
    );
  });
}
