import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScreenStateService {
  static const EventChannel _channel = EventChannel('com.kerkom.app/screen_state');

  bool _isScreenOn = true;
  StreamSubscription? _sub;
  final _screenStateController = StreamController<bool>.broadcast();

  ScreenStateService() {
    _init();
  }

  bool get isScreenOn => _isScreenOn;
  Stream<bool> get screenStateStream => _screenStateController.stream;

  void _init() {
    try {
      _sub = _channel.receiveBroadcastStream().listen(
        (dynamic event) {
          final status = event.toString();
          if (status == 'SCREEN_OFF') {
            _isScreenOn = false;
            _screenStateController.add(false);
          } else if (status == 'SCREEN_ON' || status == 'USER_PRESENT') {
            _isScreenOn = true;
            _screenStateController.add(true);
          }
        },
        onError: (dynamic error) {
          // Fallback jika bukan platform Android / channel tidak tersedia
          _isScreenOn = true;
        },
      );
    } catch (_) {
      _isScreenOn = true;
    }
  }

  void dispose() {
    _sub?.cancel();
    _screenStateController.close();
  }
}

final screenStateServiceProvider = Provider<ScreenStateService>((ref) {
  final service = ScreenStateService();
  ref.onDispose(() => service.dispose());
  return service;
});
