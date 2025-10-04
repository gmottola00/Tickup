import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tickup/core/unity/unity_bridge.dart';
import 'package:tickup/providers/unity_provider.dart';

class TanksUnityScreen extends ConsumerStatefulWidget {
  const TanksUnityScreen({super.key, this.initialScene});

  final String? initialScene;

  @override
  ConsumerState<TanksUnityScreen> createState() => _TanksUnityScreenState();
}

class _TanksUnityScreenState extends ConsumerState<TanksUnityScreen> {
  StreamSubscription<UnityEvent>? _subscription;
  final List<UnityEvent> _events = <UnityEvent>[];
  bool _unityActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bridge = ref.read(unityBridgeProvider);
      if (!bridge.isSupported) {
        _appendEvent(const UnityEvent(
          type: 'unsupported_platform',
          payload: {
            'message': 'Unity minigame is available only on Android builds.',
          },
        ));
        return;
      }
      _listenUnityEvents();
      await _startUnity();
    });
  }

  Future<void> _startUnity() async {
    final bridge = ref.read(unityBridgeProvider);
    try {
      await bridge.launch(scene: widget.initialScene ?? 'Main');
      setState(() => _unityActive = true);
    } on PlatformException catch (error) {
      _appendEvent(UnityEvent(type: 'error', payload: {
        'code': error.code,
        'message': error.message,
      }));
    } catch (error, stackTrace) {
      _appendEvent(UnityEvent(type: 'error', payload: {
        'message': error.toString(),
      }));
      debugPrintStack(label: 'Unity launch failed', stackTrace: stackTrace);
    }
  }

  void _listenUnityEvents() {
    final bridge = ref.read(unityBridgeProvider);
    _subscription = bridge.events().listen((event) {
      _appendEvent(event);
      if (event.type == 'unity_closed' || event.type == 'unity_unloaded') {
        if (mounted) {
          setState(() => _unityActive = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    final bridge = ref.read(unityBridgeProvider);
    if (_unityActive) {
      bridge.close();
    }
    super.dispose();
  }

  void _appendEvent(UnityEvent event) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, event);
      if (_events.length > 20) {
        _events.removeLast();
      }
    });
  }

  Future<void> _sendCommand(String scene) async {
    if (!_unityActive) return;
    final bridge = ref.read(unityBridgeProvider);
    await bridge.sendMessage(
      gameObject: 'GameManager',
      method: 'LoadScene',
      message: scene,
    );
  }

  Future<bool> _onWillPop() async {
    if (_unityActive) {
      final bridge = ref.read(unityBridgeProvider);
      await bridge.close();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tanks Unity Minigames'),
          actions: [
            IconButton(
              tooltip: 'Reload lobby',
              onPressed: _unityActive ? () => _sendCommand('Lobby') : null,
              icon: const Icon(Icons.home),
            ),
            IconButton(
              tooltip: 'Close Unity',
              onPressed: _unityActive
                  ? () async {
                      final bridge = ref.read(unityBridgeProvider);
                      await bridge.close();
                    }
                  : null,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: _unityActive ? () => _sendCommand('Arena01') : null,
                    child: const Text('Arena 01'),
                  ),
                  ElevatedButton(
                    onPressed: _unityActive ? () => _sendCommand('Arena02') : null,
                    child: const Text('Arena 02'),
                  ),
                  ElevatedButton(
                    onPressed: _unityActive ? () => _sendCommand('Arena03') : null,
                    child: const Text('Arena 03'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return ListTile(
                    title: Text(event.type),
                    subtitle: event.payload == null
                        ? null
                        : Text(event.payload.toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
