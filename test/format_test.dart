import 'package:bilang/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a date reads as a short month and day', () {
    expect(shortDate(DateTime(2026, 8, 27)), 'Aug 27');
    expect(shortDate(DateTime(2026, 1, 1)), 'Jan 1');
    expect(shortDate(DateTime(2026, 12, 31)), 'Dec 31');
  });

  test('a count meta line pluralises items and units', () {
    expect(
      countMeta(DateTime(2026, 8, 27), 2, 30),
      'Aug 27 · 2 items · 30 units',
    );
    expect(countMeta(DateTime(2026, 8, 27), 1, 1), 'Aug 27 · 1 item · 1 unit');
    expect(
      countMeta(DateTime(2026, 8, 27), 0, 0),
      'Aug 27 · 0 items · 0 units',
    );
  });
}
