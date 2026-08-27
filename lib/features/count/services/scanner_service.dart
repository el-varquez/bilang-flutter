import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_throttle.dart';

class ScannerService {
  ScannerService({ScanThrottle? throttle})
    : _throttle = throttle ?? ScanThrottle();

  final ScanThrottle _throttle;

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    formats: const <BarcodeFormat>[
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf14,
    ],
  );

  ValueListenable<MobileScannerState> get state => _controller;

  Stream<String> get scans => _controller.barcodes.expand((capture) {
    final values = <String>[];
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      if (!_throttle.allow(value, DateTime.now())) continue;
      values.add(value);
    }
    return values;
  });

  Future<void> start() => _controller.start();

  void resetThrottle() => _throttle.reset();

  Future<void> stop() async {
    _throttle.reset();
    await _controller.stop();
  }

  Future<void> toggleTorch() => _controller.toggleTorch();

  Future<void> dispose() => _controller.dispose();

  Widget preview({required Widget Function(BuildContext, String) onError}) {
    return MobileScanner(
      controller: _controller,
      errorBuilder: (context, error) =>
          onError(context, _messageFor(error.errorCode)),
    );
  }

  static String _messageFor(MobileScannerErrorCode code) {
    return switch (code) {
      MobileScannerErrorCode.permissionDenied =>
        'Bilang needs the camera to scan. Allow camera access, then try again.',
      MobileScannerErrorCode.unsupported =>
        'This device has no camera Bilang can use. Type barcodes instead.',
      _ => 'The camera could not start. Try again.',
    };
  }
}
