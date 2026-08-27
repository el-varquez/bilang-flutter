import 'package:bilang/features/count/services/wedge_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WedgeBuffer buffer;
  final start = DateTime(2026, 8, 27, 9);

  setUp(() => buffer = WedgeBuffer());

  void type(String characters, {DateTime? from}) {
    var at = from ?? start;
    for (final character in characters.split('')) {
      buffer.accept(character, at);
      at = at.add(const Duration(milliseconds: 10));
    }
  }

  test('a printable character is buffered, a control character is not', () {
    expect(buffer.accept('4', start), isTrue);
    expect(buffer.accept(' ', start), isFalse);
    expect(buffer.accept('\n', start), isFalse);
  });

  test('the barcode arrives on enter', () {
    type('4800888812345');

    expect(
      buffer.submit(start.add(const Duration(milliseconds: 200))),
      '4800888812345',
    );
  });

  test('enter with nothing typed emits nothing', () {
    expect(buffer.submit(start), isNull);
  });

  test('the buffer empties after it is read', () {
    type('4800888812345');
    buffer.submit(start.add(const Duration(milliseconds: 200)));

    expect(buffer.submit(start.add(const Duration(milliseconds: 300))), isNull);
  });

  test('a stale half-typed buffer is discarded', () {
    type('48');
    buffer.accept('9', start.add(const Duration(seconds: 5)));

    expect(
      buffer.submit(start.add(const Duration(seconds: 5, milliseconds: 10))),
      '9',
    );
  });

  test('a second barcode reads on its own', () {
    type('111');
    expect(buffer.submit(start.add(const Duration(milliseconds: 100))), '111');

    type('22', from: start.add(const Duration(milliseconds: 120)));
    expect(buffer.submit(start.add(const Duration(milliseconds: 150))), '22');
  });

  test('whitespace inside a burst is skipped, the rest survives', () {
    buffer.accept('4', start);
    buffer.accept(' ', start.add(const Duration(milliseconds: 10)));
    buffer.accept('7', start.add(const Duration(milliseconds: 20)));

    expect(buffer.submit(start.add(const Duration(milliseconds: 30))), '47');
  });

  test('clearing forgets a partial barcode', () {
    type('4800');
    buffer.clear();

    expect(buffer.submit(start.add(const Duration(milliseconds: 100))), isNull);
  });
}
