import 'dart:async';

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

  Future<void> launch({String? scene}) async {
    await _methodChannel.invokeMethod('launchUnity', {
      if (scene != null) 'scene': scene,
    });
  }

  Future<void> sendMessage({
    required String gameObject,
    required String method,
    String message = '',
  }) async {
    await _methodChannel.invokeMethod('sendMessage', {
      'gameObject': gameObject,
      'method': method,
      'message': message,
    });
  }

  Future<void> close() async {
    await _methodChannel.invokeMethod('closeUnity');
  }

  Stream<UnityEvent> events() {
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
}
