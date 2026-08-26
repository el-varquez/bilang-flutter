import 'package:flutter/foundation.dart';

import '../types/count_session.dart';
import '../types/scan_row.dart';

class CountStore extends ChangeNotifier {
  final List<CountSession> _sessions = <CountSession>[];
  final List<String> _scanHistory = <String>[];
  String? _activeId;

  List<CountSession> get sessions => List.unmodifiable(_sessions);

  CountSession? get active {
    for (final session in _sessions) {
      if (session.id == _activeId) return session;
    }
    return null;
  }

  bool get canUndo => _scanHistory.isNotEmpty;

  CountSession startCount(String name, {required DateTime at}) {
    final current = active;
    if (current != null) current.open = false;
    final session = CountSession(
      id: at.microsecondsSinceEpoch.toString(),
      name: name,
      startedAt: at,
    );
    _sessions.insert(0, session);
    _activeId = session.id;
    _scanHistory.clear();
    notifyListeners();
    return session;
  }

  void openCount(String id) {
    _activeId = id;
    _scanHistory.clear();
    notifyListeners();
  }

  void recordScan(String barcode, {String? name, int units = 1}) {
    final session = active;
    if (session == null || !session.open) return;
    final index = session.rows.indexWhere((row) => row.barcode == barcode);
    if (index >= 0) {
      final row = session.rows[index];
      session.rows[index] = row.copyWith(qty: row.qty + units);
    } else {
      session.rows.add(ScanRow(barcode: barcode, name: name, qty: units));
    }
    _scanHistory.add(barcode);
    notifyListeners();
  }

  void undoLastScan({int units = 1}) {
    final session = active;
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
    notifyListeners();
  }

  void setQuantity(String barcode, int qty) {
    final session = active;
    if (session == null) return;
    final index = session.rows.indexWhere((row) => row.barcode == barcode);
    if (index < 0) return;
    if (qty <= 0) {
      session.rows.removeAt(index);
    } else {
      session.rows[index] = session.rows[index].copyWith(qty: qty);
    }
    notifyListeners();
  }
}
