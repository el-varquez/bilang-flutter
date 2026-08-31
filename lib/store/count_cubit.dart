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

  Future<void> deleteCount(String id) async {
    await _storage.deleteSession(id);
    if (state.active?.id != id) {
      emit(state.copyWith(summaries: _storage.summaries()));
      return;
    }
    await _storage.setActiveCountId(null);
    emit(CountState(summaries: _storage.summaries()));
  }

  Future<ScanRow?> recordScan(
    String barcode, {
    String? name,
    int units = 1,
  }) async {
    final session = state.active;
    if (session == null || !session.open) return null;
    final rows = [...session.rows];
    final index = rows.indexWhere((row) => row.barcode == barcode);
    final ScanRow updated;
    if (index >= 0) {
      updated = rows[index].copyWith(qty: rows[index].qty + units);
      rows[index] = updated;
    } else {
      updated = ScanRow(barcode: barcode, name: name, qty: units);
      rows.add(updated);
    }
    await _apply(session.copyWith(rows: rows));
    return updated;
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
    await _apply(session.copyWith(rows: rows));
  }

  Future<void> nameRow(String barcode, String? name) async {
    final session = state.active;
    if (session == null) return;
    final rows = [...session.rows];
    final index = rows.indexWhere((row) => row.barcode == barcode);
    if (index < 0) return;
    final trimmed = name?.trim();
    final row = rows[index];
    rows[index] = ScanRow(
      barcode: row.barcode,
      name: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      qty: row.qty,
    );
    await _apply(session.copyWith(rows: rows));
  }

  Future<void> _apply(CountSession session) async {
    await _storage.saveSession(session);
    emit(state.copyWith(summaries: _storage.summaries(), active: session));
  }
}
