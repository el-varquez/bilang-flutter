import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' show Csv;
import 'package:excel/excel.dart';

import '../format.dart';
import '../types/count_session.dart';

enum ExportFormat { csv, xlsx, json }

class ExportService {
  const ExportService._();

  static const List<String> _header = ['name', 'barcode', 'qty'];

  static final Csv _writer = Csv();

  static String extensionOf(ExportFormat format) => switch (format) {
    ExportFormat.csv => 'csv',
    ExportFormat.xlsx => 'xlsx',
    ExportFormat.json => 'json',
  };

  static String mimeType(ExportFormat format) => switch (format) {
    ExportFormat.csv => 'text/csv',
    ExportFormat.xlsx =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ExportFormat.json => 'application/json',
  };

  static String fileName(CountSession session, ExportFormat format) {
    final slug = session.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safe = slug.isEmpty ? 'count' : slug;
    return 'bilang-$safe.${extensionOf(format)}';
  }

  static String csv(CountSession session) {
    final rows = <List<Object?>>[
      _header,
      for (final row in session.rows) [row.name ?? '', row.barcode, row.qty],
    ];
    return '${_writer.encode(rows)}\r\n';
  }

  static String json(CountSession session) {
    final payload = <String, Object?>{
      'app': 'Bilang',
      'session': session.name,
      'date': shortDate(session.startedAt),
      'items': [
        for (final row in session.rows)
          {'name': row.name, 'barcode': row.barcode, 'qty': row.qty},
      ],
    };
    return '${const JsonEncoder.withIndent('  ').convert(payload)}\n';
  }

  static Uint8List _xlsx(CountSession session) {
    final book = Excel.createExcel();
    final sheet = book[book.getDefaultSheet()!];
    sheet.appendRow([for (final title in _header) TextCellValue(title)]);
    for (final row in session.rows) {
      sheet.appendRow([
        TextCellValue(row.name ?? ''),
        TextCellValue(row.barcode),
        IntCellValue(row.qty),
      ]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  static Uint8List bytes(CountSession session, ExportFormat format) {
    return switch (format) {
      ExportFormat.csv => Uint8List.fromList(utf8.encode(csv(session))),
      ExportFormat.json => Uint8List.fromList(utf8.encode(json(session))),
      ExportFormat.xlsx => _xlsx(session),
    };
  }
}
