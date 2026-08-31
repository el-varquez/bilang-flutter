import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'local_store.dart';

enum LiveStatus { off, live, retrying }

class LiveClient {
  LiveClient(
    this._storage, {
    this.timeout = const Duration(seconds: 4),
    this.retryDelay = const Duration(seconds: 5),
  });

  final LocalStore _storage;
  final Duration timeout;
  final Duration retryDelay;

  final List<Map<String, Object?>> _queue = [];
  final ValueNotifier<LiveStatus> _status = ValueNotifier(LiveStatus.off);
  bool _sending = false;
  bool _disposed = false;
  Timer? _retry;

  ValueListenable<LiveStatus> get status => _status;

  void refresh() {
    if (_storage.liveUrl.isEmpty) {
      _queue.clear();
      _status.value = LiveStatus.off;
      return;
    }
    _status.value = _queue.isEmpty ? LiveStatus.live : LiveStatus.retrying;
    if (_queue.isNotEmpty) unawaited(_drain());
  }

  void send({
    required String session,
    required String barcode,
    String? name,
    required int qty,
  }) {
    if (_storage.liveUrl.isEmpty) {
      refresh();
      return;
    }
    _queue.add({
      'app': 'Bilang',
      'session': session,
      'barcode': barcode,
      'name': name,
      'qty': qty,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_drain());
  }

  Future<bool> probe(String url) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'app': 'Bilang',
              'test': true,
              'at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _drain() async {
    if (_sending || _disposed) return;
    _sending = true;
    _retry?.cancel();
    _retry = null;
    try {
      while (_queue.isNotEmpty) {
        final url = _storage.liveUrl;
        if (url.isEmpty) {
          _queue.clear();
          _status.value = LiveStatus.off;
          return;
        }
        try {
          final response = await http
              .post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(_queue.first),
              )
              .timeout(timeout);
          if (_disposed) return;
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw http.ClientException('HTTP ${response.statusCode}');
          }
          _queue.removeAt(0);
          _status.value = LiveStatus.live;
        } catch (_) {
          if (_disposed) return;
          if (_storage.liveUrl.isEmpty) {
            _queue.clear();
            _status.value = LiveStatus.off;
            return;
          }
          _status.value = LiveStatus.retrying;
          _retry = Timer(retryDelay, () => unawaited(_drain()));
          return;
        }
      }
    } finally {
      _sending = false;
    }
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _status.dispose();
  }
}
