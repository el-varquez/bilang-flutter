import 'package:flutter/foundation.dart';

import '../services/local_store.dart';
import '../types/count_session.dart';
import '../types/count_summary.dart';
import '../types/scan_row.dart';

class CountStore extends ChangeNotifier {
  CountStore(this._storage);

  final LocalStore _storage;
  final List<String> _scanHistory = <String>[];
  List<CountSummary> _summaries = const <CountSummary>[];
  CountSession? _active;

  List<CountSummary> get summaries => _summaries;

  CountSession? get active => _active;

  bool get canUndo => _scanHistory.isNotEmpty;

  Future<void> hydrate() async {
    _summaries = _storage.summaries();
    final id = _storage.activeCountId;
    _active = id == null ? null : await _storage.loadSession(id);
    notifyListeners();
  }

  Future<void> startCount(String name, {required DateTime at}) async {
    final current = _active;
    if (current != null) {
      current.open = false;
      await _storage.saveSession(current);
    }
    final session = CountSession(
      id: at.microsecondsSinceEpoch.toString(),
      name: name,
      startedAt: at,
    );
    _active = session;
    _scanHistory.clear();
    await _storage.saveSession(session);
    await _storage.setActiveCountId(session.id);
    _summaries = _storage.summaries();
    notifyListeners();
  }

  Future<void> openCount(String id) async {
    _active = await _storage.loadSession(id);
    _scanHistory.clear();
    await _storage.setActiveCountId(id);
    notifyListeners();
  }

  Future<void> recordScan(String barcode, {String? name, int units = 1}) async {
    final session = _active;
    if (session == null || !session.open) return;
    final index = session.rows.indexWhere((row) => row.barcode == barcode);
    if (index >= 0) {
      final row = session.rows[index];
      session.rows[index] = row.copyWith(qty: row.qty + units);
    } else {
      session.rows.add(ScanRow(barcode: barcode, name: name, qty: units));
    }
    _scanHistory.add(barcode);
    await _persist(session);
  }

  Future<void> undoLastScan({int units = 1}) async {
    final session = _active;
    if (session == null || _scanHistory.isEmpty) return;
    final barcode = _scanHistory.removeLast();
    final index = session.rows.indexWhere((row) => row.barcode == barcode);
    if (index < 0) return;
    final row = session.rows[index];
    if (row.qty <= units) {
      session.rows.removeAt(index);
    } else {
      session.rows[index] = row.copyWith(qty: row.qty - units);
    }
    await _persist(session);
  }

  Future<void> setQuantity(String barcode, int qty) async {
    final session = _active;
    if (session == null) return;
    final index = session.rows.indexWhere((row) => row.barcode == barcode);
    if (index < 0) return;
    if (qty <= 0) {
      session.rows.removeAt(index);
    } else {
      session.rows[index] = session.rows[index].copyWith(qty: qty);
    }
    await _persist(session);
  }

  Future<void> _persist(CountSession session) async {
    await _storage.saveSession(session);
    _summaries = _storage.summaries();
    notifyListeners();
  }
}
