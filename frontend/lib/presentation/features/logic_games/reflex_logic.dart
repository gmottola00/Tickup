import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Logica del mini-gioco "Reflex Tap"
class ReflexLogic extends ChangeNotifier {
  int score = 0;
  double timeLeft;
  late Timer _timer;
  Offset targetPosition = Offset.zero;

  ReflexLogic({this.timeLeft = 10.0}); // durata di default 10s

  void start() {
    score = 0;
    _spawnTarget();
    _timer = Timer.periodic(Duration(milliseconds: 100), (t) {
      timeLeft -= 0.1;
      if (timeLeft <= 0) {
        _timer.cancel();
      }
      notifyListeners();
    });
  }

  void _spawnTarget() {
    final rand = Random();
    targetPosition = Offset(rand.nextDouble(), rand.nextDouble());
    notifyListeners();
  }

  /// Gestisce il tap dell'utente
  void tap(Offset tapPos, Size size) {
    final dx = (tapPos.dx / size.width) - targetPosition.dx;
    final dy = (tapPos.dy / size.height) - targetPosition.dy;
    if (dx * dx + dy * dy < 0.02) {
      score++;
      _spawnTarget();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
