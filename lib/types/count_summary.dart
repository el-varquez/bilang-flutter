import 'count_session.dart';

class CountSummary {
  const CountSummary({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.open,
    required this.itemCount,
    required this.unitCount,
  });

  final String id;
  final String name;
  final DateTime startedAt;
  final bool open;
  final int itemCount;
  final int unitCount;

  factory CountSummary.of(CountSession session) => CountSummary(
    id: session.id,
    name: session.name,
    startedAt: session.startedAt,
    open: session.open,
    itemCount: session.rows.length,
    unitCount: session.units,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'startedAt': startedAt.toIso8601String(),
    'open': open,
    'itemCount': itemCount,
    'unitCount': unitCount,
  };

  factory CountSummary.fromJson(Map<String, Object?> json) => CountSummary(
    id: json['id']! as String,
    name: json['name']! as String,
    startedAt: DateTime.parse(json['startedAt']! as String),
    open: json['open']! as bool,
    itemCount: json['itemCount']! as int,
    unitCount: json['unitCount']! as int,
  );
}
