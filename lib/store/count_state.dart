import 'package:equatable/equatable.dart';

import '../types/count_session.dart';
import '../types/count_summary.dart';

class CountState extends Equatable {
  const CountState({
    this.summaries = const <CountSummary>[],
    this.active,
  });

  final List<CountSummary> summaries;
  final CountSession? active;

  CountState copyWith({
    List<CountSummary>? summaries,
    CountSession? active,
    bool clearActive = false,
  }) => CountState(
    summaries: summaries ?? this.summaries,
    active: clearActive ? null : (active ?? this.active),
  );

  @override
  List<Object?> get props => [summaries, active];
}
