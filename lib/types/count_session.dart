import 'package:equatable/equatable.dart';

import 'scan_row.dart';

class CountSession extends Equatable {
  const CountSession({
    required this.id,
    required this.name,
    required this.startedAt,
    this.open = true,
    this.rows = const <ScanRow>[],
  });

  final String id;
  final String name;
  final DateTime startedAt;
  final bool open;
  final List<ScanRow> rows;

  int get units => rows.fold(0, (sum, row) => sum + row.qty);

  CountSession copyWith({String? name, bool? open, List<ScanRow>? rows}) =>
      CountSession(
        id: id,
        name: name ?? this.name,
        startedAt: startedAt,
        open: open ?? this.open,
        rows: rows ?? this.rows,
      );

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

  @override
  List<Object?> get props => [id, name, startedAt, open, rows];
}
