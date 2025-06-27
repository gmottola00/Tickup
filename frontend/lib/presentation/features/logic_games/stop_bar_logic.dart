import 'dart:async';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// INTERFACCIA + IMPLEMENTAZIONE MOCK DEL BACKEND
/// ─────────────────────────────────────────────────────────────
abstract class GameResultService {
  Future<void> submitResult({
    required String gameId,
    required int score,
    required Duration duration,
  });
}

/// Finto backend: 400 ms di delay e stampa su console.
/// Sostituiscilo con Dio/http e il tuo endpoint reale.
class MockGameResultService implements GameResultService {
  @override
  Future<void> submitResult({
    required String gameId,
    required int score,
    required Duration duration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    debugPrint(
      '[MOCK] Result sent → game:$gameId score:$score duration:${duration.inSeconds}s',
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// LOGICA DEL GIOCO
/// ─────────────────────────────────────────────────────────────
class StopBarLogic extends ChangeNotifier {
  StopBarLogic({GameResultService? service})
      : _resultService = service ?? MockGameResultService();

  // ───────── Costanti di gioco ─────────
  static const double greenStart = 0.4;
  static const double greenEnd = 0.6;
  static const Duration gameDuration = Duration(seconds: 30);
  static const int pointPerHit = 10;

  // ───────── Stato dinamico ─────────
  double position = 0.0;
  bool movingForward = true;
  int score = 0;
  bool gameOver = false;
  Duration elapsed = Duration.zero; // tempo trascorso

  // ───────── Internals ─────────
  final GameResultService _resultService;
  Timer? _ticker; // 60 FPS (~16 ms)
  late DateTime _startTime;

  // ───────── Api pubblica ─────────
  void start() {
    _resetState();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _tick);
    notifyListeners();
  }

  /// Chiamato a ogni tap sul pulsante "STOP!"
  void tap() {
    if (gameOver) return;

    // Se il cursore è nella zona verde, assegna punti
    if (position >= greenStart && position <= greenEnd) {
      score += pointPerHit;
      notifyListeners();
    }
  }

  /// Tempo rimanente in secondi arrotondati (utile per la UI)
  int get remainingSeconds =>
      (gameDuration - elapsed).inSeconds.clamp(0, gameDuration.inSeconds);

  // ───────── Internals ─────────
  void _resetState() {
    _ticker?.cancel();
    position = 0;
    movingForward = true;
    score = 0;
    gameOver = false;
    elapsed = Duration.zero;
    _startTime = DateTime.now();
  }

  void _tick(Timer timer) {
    // Aggiorna posizione barra
    if (movingForward) {
      position += 0.01;
      if (position >= 1.0) movingForward = false;
    } else {
      position -= 0.01;
      if (position <= 0.0) movingForward = true;
    }

    // Aggiorna tempo
    elapsed = DateTime.now().difference(_startTime);
    if (elapsed >= gameDuration) {
      _endGame();
    } else {
      notifyListeners();
    }
  }

  Future<void> _endGame() async {
    gameOver = true;
    _ticker?.cancel();
    // invia risultato al backend (mock)
    try {
      await _resultService.submitResult(
        gameId: 'stop_bar',
        score: score,
        duration: elapsed,
      );
    } catch (e, st) {
      debugPrint('Errore invio risultato: $e\n$st');
    }
    notifyListeners();
  }

  void restart() => start();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
