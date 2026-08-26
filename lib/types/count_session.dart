import 'scan_row.dart';

class CountSession {
  CountSession({
    required this.id,
    required this.name,
    required this.startedAt,
    this.open = true,
    List<ScanRow>? rows,
  }) : rows = rows ?? <ScanRow>[];

  final String id;
  final String name;
  final DateTime startedAt;
  final List<ScanRow> rows;
  bool open;

  int get units => rows.fold(0, (sum, row) => sum + row.qty);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'startedAt': startedAt.toIso8601String(),
    'open': open,
    'items': rows.map((row) => row.toJson()).toList(),
  };

  factory CountSession.fromJson(Map<String, Object?> json) => CountSession(
    id: json['id']! as String,
    name: json['name']! as String,
    startedAt: DateTime.parse(json['startedAt']! as String),
    open: json['open']! as bool,
    rows: (json['items']! as List<Object?>)
        .map((item) => ScanRow.fromJson(item! as Map<String, Object?>))
        .toList(),
  );
}
