import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_store.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage) : super(const SettingsState());

  final LocalStore _storage;

  void hydrate() {
    emit(
      SettingsState(
        vibrate: _storage.vibrate,
        beep: _storage.beep,
        batchSize: _storage.batchSize,
        liveUrl: _storage.liveUrl,
      ),
    );
  }

  Future<void> setVibrate(bool value) async {
    await _storage.setVibrate(value);
    emit(state.copyWith(vibrate: value));
  }

  Future<void> setBeep(bool value) async {
    await _storage.setBeep(value);
    emit(state.copyWith(beep: value));
  }

  Future<void> setBatchSize(int value) async {
    final size = value > 1 ? value : 0;
    await _storage.setBatchSize(size);
    emit(state.copyWith(batchSize: size));
  }

  Future<void> setLiveUrl(String value) async {
    final url = value.trim();
    await _storage.setLiveUrl(url);
    emit(state.copyWith(liveUrl: url));
  }

  Future<void> deleteAllCounts() => _storage.deleteAllCounts();
}
