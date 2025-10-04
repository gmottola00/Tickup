import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UnityEvent {
  const UnityEvent({required this.type, this.payload});

  final String type;
  final Map<String, dynamic>? payload;
}

class UnityBridge {
  UnityBridge._internal();

  static final UnityBridge instance = UnityBridge._internal();

  static const _methodChannel = MethodChannel('tickup/unity/methods');
  static const _eventChannel = EventChannel('tickup/unity/events');

  Stream<UnityEvent>? _eventStream;

  bool get isSupported => _isPlatformSupported;

  Future<void> launch({String? scene}) async {
    _ensureSupported();
    await _methodChannel.invokeMethod('launchUnity', {
      if (scene != null) 'scene': scene,
    });
  }

  Future<void> sendMessage({
    required String gameObject,
    required String method,
    String message = '',
  }) async {
    _ensureSupported();
    await _methodChannel.invokeMethod('sendMessage', {
      'gameObject': gameObject,
      'method': method,
      'message': message,
    });
  }

  Future<void> close() async {
    _ensureSupported();
    await _methodChannel.invokeMethod('closeUnity');
  }

  Stream<UnityEvent> events() {
    if (!_isPlatformSupported) {
      return _eventStream ??= Stream<UnityEvent>.value(
        const UnityEvent(
          type: 'unsupported_platform',
          payload: {
            'message': 'Unity integration is available only on supported mobile platforms.',
          },
        ),
      ).asBroadcastStream();
    }

    return _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event != null)
        .map<UnityEvent>((dynamic event) {
      if (event is Map) {
        final payload = Map<String, dynamic>.from(event as Map);
        final type = payload.remove('type')?.toString() ?? 'unknown';
        return UnityEvent(type: type, payload: payload);
      }
      return UnityEvent(type: 'raw', payload: {'value': event});
    }).asBroadcastStream();
  }

  void _ensureSupported() {
    if (!_isPlatformSupported) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: 'Unity integration is available only on supported mobile platforms.',
      );
    }
  }

  bool get _isPlatformSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }
}
