import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.vibrate = true,
    this.beep = false,
    this.batchSize = 0,
    this.liveUrl = '',
  });

  final bool vibrate;
  final bool beep;
  final int batchSize;
  final String liveUrl;

  bool get batchOn => batchSize > 1;
  bool get liveOn => liveUrl.isNotEmpty;

  SettingsState copyWith({
    bool? vibrate,
    bool? beep,
    int? batchSize,
    String? liveUrl,
  }) => SettingsState(
    vibrate: vibrate ?? this.vibrate,
    beep: beep ?? this.beep,
    batchSize: batchSize ?? this.batchSize,
    liveUrl: liveUrl ?? this.liveUrl,
  );

  @override
  List<Object?> get props => [vibrate, beep, batchSize, liveUrl];
}
