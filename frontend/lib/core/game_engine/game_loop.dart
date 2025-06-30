import 'dart:async';
import 'package:flutter/foundation.dart';

/// Ciclo di gioco generico: chiama `update()` a ogni tick
/// passando il delta-time in secondi, poi notifica i listener.
/// Usa [start] e [stop] per controllare il ciclo.
abstract class GameLoop extends ChangeNotifier {
  GameLoop({required this.tick});
  final Duration tick;

  Timer? _timer;
  DateTime? _lastStamp;

  /// Avvia o ri-avvia il ciclo.
  void start() {
    stop();
    _lastStamp = DateTime.now();
    _timer = Timer.periodic(tick, (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastStamp!).inMicroseconds / 1e6;
      _lastStamp = now;
      update(dt);
      notifyListeners();
    });
  }

  /// Ferma il ciclo.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Logica di aggiornamento-gioco.
  /// [dt] è il delta-time in secondi dall’ultimo tick.
  void update(double dt);

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
