import 'package:equatable/equatable.dart';

import '../types/count_session.dart';
import '../types/count_summary.dart';

class ScanEvent extends Equatable {
  const ScanEvent({required this.barcode, required this.units});

  final String barcode;
  final int units;

  @override
  List<Object?> get props => [barcode, units];
}

class CountState extends Equatable {
  const CountState({
    this.summaries = const <CountSummary>[],
    this.active,
    this.history = const <ScanEvent>[],
  });

  final List<CountSummary> summaries;
  final CountSession? active;
  final List<ScanEvent> history;

  bool get canUndo => history.isNotEmpty;

  CountState copyWith({
    List<CountSummary>? summaries,
    CountSession? active,
    bool clearActive = false,
    List<ScanEvent>? history,
  }) => CountState(
    summaries: summaries ?? this.summaries,
    active: clearActive ? null : (active ?? this.active),
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [summaries, active, history];
}
