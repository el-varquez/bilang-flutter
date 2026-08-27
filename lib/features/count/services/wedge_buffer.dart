class WedgeBuffer {
  WedgeBuffer({this.idleGap = const Duration(seconds: 1)});

  final Duration idleGap;

  final StringBuffer _typed = StringBuffer();
  DateTime? _lastAt;

  bool accept(String character, DateTime now) {
    if (character.length != 1) return false;
    final code = character.codeUnitAt(0);
    if (code < 0x21 || code > 0x7e) return false;

    _dropIfStale(now);
    _typed.write(character);
    _lastAt = now;
    return true;
  }

  String? submit(DateTime now) {
    _dropIfStale(now);
    final value = _typed.toString();
    _reset();
    return value.isEmpty ? null : value;
  }

  void clear() => _reset();

  void _dropIfStale(DateTime now) {
    final last = _lastAt;
    if (last != null && now.difference(last) >= idleGap) _reset();
  }

  void _reset() {
    _typed.clear();
    _lastAt = null;
  }
}
