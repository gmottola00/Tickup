import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tickup/core/game_engine/game_engine.dart';

/// Logica del mini-gioco "Ferma la barra"
class StopBarLogic extends ChangeNotifier {
  double position = 0.0;
  bool movingForward = true;
  Timer? _timer;
  bool gameOver = false;
  late int score;
  late Duration duration;

  final double greenStart = 0.4;
  final double greenEnd = 0.6;
  late DateTime _startTime;

  void start() {
    gameOver = false;
    position = 0;
    movingForward = true;
    score = 0;
    _startTime = DateTime.now();

    _timer = Timer.periodic(Duration(milliseconds: 16), (_) {
      if (movingForward) {
        position += 0.01;
        if (position >= 1.0) movingForward = false;
      } else {
        position -= 0.01;
        if (position <= 0.0) movingForward = true;
      }
      notifyListeners();
    });
  }

  /// Ferma la barra e calcola il risultato
  void stop(Function(GameResult) onComplete) {
    _timer?.cancel();
    gameOver = true;
    duration = DateTime.now().difference(_startTime);
    if (position >= greenStart && position <= greenEnd) {
      score = 10;
    } else {
      score = 0;
    }
    onComplete(GameResult(score: score, duration: duration));
    notifyListeners();
  }

  void restart() {
    _timer?.cancel();
    start();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
