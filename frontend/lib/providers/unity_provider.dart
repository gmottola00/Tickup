import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tickup/core/unity/unity_bridge.dart';

final unityBridgeProvider = Provider<UnityBridge>((ref) {
  return UnityBridge.instance;
});

final unityEventsProvider = StreamProvider<UnityEvent>((ref) {
  final bridge = ref.watch(unityBridgeProvider);
  return bridge.events();
});
