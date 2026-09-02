import 'package:hive_ce_flutter/hive_flutter.dart';

import '../types/count_session.dart';
import '../types/count_summary.dart';

class LocalStore {
  LocalStore._(this._settings);

  static const int currentSchemaVersion = 1;
  static const String settingsBoxName = 'bilang_settings';
  static const String indexBoxName = 'bilang_count_index';
  static const String countsBoxName = 'bilang_counts';

  static const String _keySchemaVersion = 'schemaVersion';
  static const String _keyVibrate = 'vibrate';
  static const String _keyBeep = 'beep';
  static const String _keyBatchSize = 'batchSize';
  static const String _keyActiveCountId = 'activeCountId';

  final Box _settings;
  Box? _index;
  LazyBox? _counts;

  static Future<LocalStore> openForApp() async {
    await Hive.initFlutter();
    return open();
  }

  static Future<LocalStore> open() async {
    final settings = await _openBox(settingsBoxName);
    final store = LocalStore._(settings);
    await store._stampSchemaVersion();
    return store;
  }

  static Future<Box> _openBox(String name) async {
    try {
      return await Hive.openBox(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox(name);
    }
  }

  static Future<LazyBox> _openLazyBox(String name) async {
    try {
      return await Hive.openLazyBox(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return Hive.openLazyBox(name);
    }
  }

  Future<void> _stampSchemaVersion() async {
    if (_settings.get(_keySchemaVersion) == null) {
      await _settings.put(_keySchemaVersion, currentSchemaVersion);
    }
  }

  Future<void> hydrate() async {
    _index ??= await _openBox(indexBoxName);
    _counts ??= await _openLazyBox(countsBoxName);
  }

  Future<void> close() => Hive.close();

  int get schemaVersion =>
      _settings.get(_keySchemaVersion, defaultValue: currentSchemaVersion)
          as int;

  bool get vibrate => _settings.get(_keyVibrate, defaultValue: true) as bool;
  Future<void> setVibrate(bool value) => _settings.put(_keyVibrate, value);

  bool get beep => _settings.get(_keyBeep, defaultValue: false) as bool;
  Future<void> setBeep(bool value) => _settings.put(_keyBeep, value);

  int get batchSize => _settings.get(_keyBatchSize, defaultValue: 0) as int;
  Future<void> setBatchSize(int value) => _settings.put(_keyBatchSize, value);

  String? get activeCountId => _settings.get(_keyActiveCountId) as String?;
  Future<void> setActiveCountId(String? value) async {
    if (value == null) {
      await _settings.delete(_keyActiveCountId);
    } else {
      await _settings.put(_keyActiveCountId, value);
    }
  }

  Box get _requireIndex {
    final box = _index;
    if (box == null) {
      throw StateError('LocalStore.hydrate() must run before reading counts');
    }
    return box;
  }

  LazyBox get _requireCounts {
    final box = _counts;
    if (box == null) {
      throw StateError('LocalStore.hydrate() must run before reading counts');
    }
    return box;
  }

  List<CountSummary> summaries() {
    final list = _requireIndex.values
        .map((raw) => CountSummary.fromJson(_json(raw as Map)))
        .toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  Future<CountSession?> loadSession(String id) async {
    final raw = await _requireCounts.get(id);
    if (raw == null) return null;
    return CountSession.fromJson(_json(raw as Map));
  }

  Future<void> saveSession(CountSession session) async {
    await _requireCounts.put(session.id, session.toJson());
    await _requireIndex.put(session.id, CountSummary.of(session).toJson());
  }

  Future<void> deleteSession(String id) async {
    await _requireCounts.delete(id);
    await _requireIndex.delete(id);
  }

  Future<void> deleteAllCounts() async {
    await _requireCounts.clear();
    await _requireIndex.clear();
  }

  static Map<String, Object?> _json(Map raw) =>
      _normalise(raw)! as Map<String, Object?>;

  static Object? _normalise(Object? value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key as String, _normalise(item)),
      );
    }
    if (value is List) {
      return value.map(_normalise).toList();
    }
    return value;
  }
}
