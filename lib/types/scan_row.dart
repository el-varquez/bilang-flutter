import 'package:equatable/equatable.dart';

class ScanRow extends Equatable {
  const ScanRow({required this.barcode, this.name, this.qty = 1});

  final String barcode;
  final String? name;
  final int qty;

  ScanRow copyWith({String? name, int? qty}) => ScanRow(
    barcode: barcode,
    name: name ?? this.name,
    qty: qty ?? this.qty,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'barcode': barcode,
    'qty': qty,
  };

  factory ScanRow.fromJson(Map<String, Object?> json) => ScanRow(
    barcode: json['barcode']! as String,
    name: json['name'] as String?,
    qty: json['qty']! as int,
  );

  @override
  List<Object?> get props => [barcode, name, qty];
}
