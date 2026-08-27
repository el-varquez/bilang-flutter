import 'package:flutter/services.dart';

import 'local_store.dart';

class FeedbackService {
  const FeedbackService(this._storage);

  final LocalStore _storage;

  Future<void> scanned() async {
    if (_storage.vibrate) {
      await HapticFeedback.mediumImpact();
    }
    if (_storage.beep) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
