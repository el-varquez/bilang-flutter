class ScanThrottle {
  ScanThrottle({this.window = const Duration(milliseconds: 1200)});

  final Duration window;

  String? _lastValue;
  DateTime? _lastAt;

  bool allow(String value, DateTime now) {
    final last = _lastAt;
    final repeat =
        _lastValue == value && last != null && now.difference(last) < window;
    _lastValue = value;
    _lastAt = now;
    return !repeat;
  }

  void reset() {
    _lastValue = null;
    _lastAt = null;
  }
}
