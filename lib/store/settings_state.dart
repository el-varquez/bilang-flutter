import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.vibrate = true,
    this.beep = false,
    this.batchSize = 0,
  });

  final bool vibrate;
  final bool beep;
  final int batchSize;

  bool get batchOn => batchSize > 1;

  SettingsState copyWith({bool? vibrate, bool? beep, int? batchSize}) =>
      SettingsState(
        vibrate: vibrate ?? this.vibrate,
        beep: beep ?? this.beep,
        batchSize: batchSize ?? this.batchSize,
      );

  @override
  List<Object?> get props => [vibrate, beep, batchSize];
}
