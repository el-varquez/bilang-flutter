import 'dart:convert';

import 'package:bilang/services/export_service.dart';
import 'package:bilang/types/count_session.dart';
import 'package:bilang/types/scan_row.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

CountSession sessionWith(List<ScanRow> rows, {String name = 'Bodega count'}) =>
    CountSession(
      id: 's1',
      name: name,
      startedAt: DateTime(2026, 8, 27),
      rows: rows,
    );

void main() {
  group('csv', () {
    test('it writes the header and one row per count row, oldest first', () {
      final csv = ExportService.csv(
        sessionWith(const [
          ScanRow(barcode: '4800888812345', name: 'Kopiko Blanca Twin', qty: 24),
          ScanRow(barcode: '4800194115817', name: 'Sky Flakes', qty: 6),
        ]),
      );

      expect(
        csv,
        'name,barcode,qty\r\n'
        'Kopiko Blanca Twin,4800888812345,24\r\n'
        'Sky Flakes,4800194115817,6\r\n',
      );
    });

    test('an unnamed row leaves the name field empty', () {
      final csv = ExportService.csv(
        sessionWith(const [ScanRow(barcode: '4800361413480', qty: 3)]),
      );

      expect(csv, 'name,barcode,qty\r\n,4800361413480,3\r\n');
    });

    test('a name containing a comma is quoted', () {
      final csv = ExportService.csv(
        sessionWith(const [
          ScanRow(barcode: '111', name: 'Milk, evaporated', qty: 2),
        ]),
      );

      expect(csv, contains('"Milk, evaporated",111,2'));
    });

    test('a name containing a quote is escaped', () {
      final csv = ExportService.csv(
        sessionWith(const [
          ScanRow(barcode: '111', name: 'Ligo 5" tin', qty: 1),
        ]),
      );

      expect(csv, contains('"Ligo 5"" tin",111,1'));
    });

    test('an empty count is still a valid file', () {
      expect(ExportService.csv(sessionWith(const [])), 'name,barcode,qty\r\n');
    });
  });

  group('json', () {
    test('it carries the app, session, date and items', () {
      final text = ExportService.json(
        sessionWith(const [
          ScanRow(barcode: '4800888812345', name: 'Kopiko Blanca Twin', qty: 24),
        ]),
      );

      expect(text.endsWith('\n'), isTrue);

      final decoded = jsonDecode(text) as Map<String, Object?>;
      expect(decoded['app'], 'Bilang');
      expect(decoded['session'], 'Bodega count');
      expect(decoded['date'], 'Aug 27');

      final items = decoded['items']! as List<Object?>;
      expect(items.length, 1);
      expect(items.single, {
        'name': 'Kopiko Blanca Twin',
        'barcode': '4800888812345',
        'qty': 24,
      });
    });

    test('an unnamed row carries a null name, not an empty string', () {
      final text = ExportService.json(
        sessionWith(const [ScanRow(barcode: '4800361413480', qty: 3)]),
      );

      final items =
          (jsonDecode(text) as Map<String, Object?>)['items']! as List<Object?>;
      expect((items.single as Map<String, Object?>)['name'], isNull);
    });

    test('it is indented two spaces', () {
      final text = ExportService.json(
        sessionWith(const [ScanRow(barcode: '111', qty: 1)]),
      );

      expect(text, contains('\n  "app": "Bilang"'));
    });
  });

  group('file name', () {
    test('it slugs the count name and takes the format extension', () {
      final session = sessionWith(const []);

      expect(
        ExportService.fileName(session, ExportFormat.csv),
        'bilang-bodega-count.csv',
      );
      expect(
        ExportService.fileName(session, ExportFormat.json),
        'bilang-bodega-count.json',
      );
      expect(
        ExportService.fileName(session, ExportFormat.xlsx),
        'bilang-bodega-count.xlsx',
      );
    });

    test('punctuation and spacing collapse to single hyphens', () {
      final session = sessionWith(const [], name: 'Stock count — Aug 27');

      expect(
        ExportService.fileName(session, ExportFormat.csv),
        'bilang-stock-count-aug-27.csv',
      );
    });

    test('a name that slugs to nothing still produces a usable file name', () {
      final session = sessionWith(const [], name: '!!!');

      expect(
        ExportService.fileName(session, ExportFormat.csv),
        'bilang-count.csv',
      );
    });
  });

  group('xlsx', () {
    test('it writes one sheet with the header and the rows', () {
      final bytes = ExportService.bytes(
        sessionWith(const [
          ScanRow(barcode: '4800888812345', name: 'Kopiko Blanca Twin', qty: 24),
          ScanRow(barcode: '4800361413480', qty: 3),
        ]),
        ExportFormat.xlsx,
      );

      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables[book.tables.keys.first]!;

      expect(sheet.rows.length, 3);
      expect(
        sheet.rows.first.map((cell) => cell?.value?.toString()).toList(),
        ['name', 'barcode', 'qty'],
      );

      final first = sheet.rows[1];
      expect(first[0]?.value?.toString(), 'Kopiko Blanca Twin');
      expect(first[1]?.value?.toString(), '4800888812345');
    });

    test('quantities are numbers a spreadsheet can sum', () {
      final bytes = ExportService.bytes(
        sessionWith(const [ScanRow(barcode: '111', qty: 24)]),
        ExportFormat.xlsx,
      );

      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables[book.tables.keys.first]!;

      expect(sheet.rows[1][2]?.value, isA<IntCellValue>());
    });

    test('an unnamed row leaves the name cell empty, not the word null', () {
      final bytes = ExportService.bytes(
        sessionWith(const [ScanRow(barcode: '111', qty: 1)]),
        ExportFormat.xlsx,
      );

      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables[book.tables.keys.first]!;
      final name = sheet.rows[1][0]?.value?.toString() ?? '';

      expect(name, isEmpty);
    });

    test('an empty count still produces a readable workbook', () {
      final bytes = ExportService.bytes(
        sessionWith(const []),
        ExportFormat.xlsx,
      );

      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables[book.tables.keys.first]!;

      expect(sheet.rows.length, 1);
    });
  });

  group('mime types', () {
    test('each format carries the type a share sheet expects', () {
      expect(ExportService.mimeType(ExportFormat.csv), 'text/csv');
      expect(ExportService.mimeType(ExportFormat.json), 'application/json');
      expect(
        ExportService.mimeType(ExportFormat.xlsx),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });
  });
}
