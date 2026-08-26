import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_store.dart';
import '../types/count_session.dart';
import '../types/scan_row.dart';
import 'count_state.dart';

class CountCubit extends Cubit<CountState> {
  CountCubit(this._storage) : super(const CountState());

  final LocalStore _storage;

  Future<void> hydrate() async {
    final id = _storage.activeCountId;
    final active = id == null ? null : await _storage.loadSession(id);
    emit(CountState(summaries: _storage.summaries(), active: active));
  }

  Future<void> startCount(String name, {required DateTime at}) async {
    final current = state.active;
    if (current != null && current.open) {
      await _storage.saveSession(current.copyWith(open: false));
    }
    final session = CountSession(
      id: at.microsecondsSinceEpoch.toString(),
      name: name,
      startedAt: at,
    );
    await _storage.saveSession(session);
    await _storage.setActiveCountId(session.id);
    emit(CountState(summaries: _storage.summaries(), active: session));
  }

  Future<void> openCount(String id) async {
    final session = await _storage.loadSession(id);
    if (session == null) return;
    await _storage.setActiveCountId(id);
    emit(CountState(summaries: _storage.summaries(), active: session));
  }

  Future<void> recordScan(String barcode, {String? name, int units = 1}) async {
    final session = state.active;
    if (session == null || !session.open) return;
    final rows = [...session.rows];
    final index = rows.indexWhere((row) => row.barcode == barcode);
    if (index >= 0) {
      rows[index] = rows[index].copyWith(qty: rows[index].qty + units);
    } else {
      rows.add(ScanRow(barcode: barcode, name: name, qty: units));
    }
    await _apply(
      session.copyWith(rows: rows),
      history: [...state.history, ScanEvent(barcode: barcode, units: units)],
    );
  }

  Future<void> undoLastScan() async {
    final session = state.active;
    if (session == null || state.history.isEmpty) return;
    final history = [...state.history];
    final event = history.removeLast();
    final rows = [...session.rows];
    final index = rows.indexWhere((row) => row.barcode == event.barcode);
    if (index < 0) return;
    if (rows[index].qty <= event.units) {
      rows.removeAt(index);
    } else {
      rows[index] = rows[index].copyWith(qty: rows[index].qty - event.units);
    }
    await _apply(session.copyWith(rows: rows), history: history);
  }

  Future<void> setQuantity(String barcode, int qty) async {
    final session = state.active;
    if (session == null) return;
    final rows = [...session.rows];
    final index = rows.indexWhere((row) => row.barcode == barcode);
    if (index < 0) return;
    if (qty <= 0) {
      rows.removeAt(index);
    } else {
      rows[index] = rows[index].copyWith(qty: qty);
    }
    await _apply(session.copyWith(rows: rows), history: state.history);
  }

  Future<void> _apply(
    CountSession session, {
    required List<ScanEvent> history,
  }) async {
    await _storage.saveSession(session);
    emit(
      state.copyWith(
        summaries: _storage.summaries(),
        active: session,
        history: history,
      ),
    );
  }
}
