import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tickup/core/game_engine/game_loop/game_loop.dart';

/// --- Modelli base ---------------------------------------------------------

class Bullet {
  Bullet({required this.x, required this.y});
  double x; // centro
  double y; // centro
  static const double size = 6;
  Rect toRect() =>
      Rect.fromCenter(center: Offset(x, y), width: size, height: size * 2);
}

class Alien {
  Alien({required this.x, required this.y});
  double x;
  double y;
  bool alive = true;
  static const double size = 24;
  Rect toRect() =>
      Rect.fromCenter(center: Offset(x, y), width: size, height: size);
}

/// --- Mixin Tempo ----------------------------------------------------------

mixin TimedGame on GameLoop {
  double totalTime = 60;
  double timeLeft = 60;

  bool get gameOver => timeLeft <= 0;

  @protected
  void updateTimer(double dt) {
    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      onGameOver();
    }
  }

  void onGameOver();
}

/// --- Logica Space Invaders -----------------------------------------------

class SpaceInvadersLogic extends GameLoop with TimedGame {
  SpaceInvadersLogic({super.tick = const Duration(milliseconds: 16)});

  // Dimensioni disponibili (impostate via setSize dallo UI)
  Size _size = Size.zero;
  double get width => _size.width;
  double get height => _size.height;

  // Stato di gioco
  double playerX = 0; // centro nave, in pixel
  final List<Bullet> bullets = [];
  final List<Alien> aliens = [];
  int score = 0;

  // Costanti
  static const double _playerSize = 28;
  static const double _playerSpeed = 260; // px/s
  static const double _bulletSpeed = 420; // px/s
  static const double _alienDownSpeed = 30; // px/s

  bool _gameOver = false;
  bool get gameOver => _gameOver;

  /// Deve essere chiamato (tipicamente in build) per far sapere la grandezza.
  void setSize(Size size) {
    if (size != _size) {
      _size = size;
      _initLevel();
    }
  }

  void _initLevel() {
    playerX = width / 2;
    bullets.clear();
    aliens
      ..clear()
      ..addAll(_createAlienWave());
    score = 0;
    timeLeft = totalTime;
    _gameOver = false;
  }

  List<Alien> _createAlienWave() {
    const cols = 8;
    const rows = 3;
    final gap = 40.0;
    final startX = (width - ((cols - 1) * gap)) / 2;
    final startY = 60.0;
    final list = <Alien>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        list.add(Alien(
          x: startX + c * gap,
          y: startY + r * gap,
        ));
      }
    }
    return list;
  }

  /// Controlli ----------------------------------------------------------------

  void moveLeft() => playerX = max(_playerSize / 2, playerX - 16);
  void moveRight() => playerX = min(width - _playerSize / 2, playerX + 16);

  void fire() {
    if (_gameOver) return;
    bullets.add(Bullet(x: playerX, y: height - _playerSize));
  }

  /// Ciclo di gioco -----------------------------------------------------------

  @override
  void update(double dt) {
    if (_gameOver) return;

    // Timer
    updateTimer(dt);
    if (_gameOver) return;

    // Aggiorna proiettili
    for (final b in bullets) {
      b.y -= _bulletSpeed * dt;
    }
    bullets.removeWhere((b) => b.y < 0);

    // Aggiorna alieni (cadono lentamente)
    for (final a in aliens) {
      if (a.alive) a.y += _alienDownSpeed * dt;
    }

    // Collisioni bullet-alien
    for (final b in bullets) {
      for (final a in aliens) {
        if (a.alive && a.toRect().overlaps(b.toRect())) {
          a.alive = false;
          score += 10;
          b.y = -10; // rimuovilo dopo
          break;
        }
      }
    }
    bullets.removeWhere((b) => b.y < 0);
    // Game-over se un alieno supera il player
    if (aliens.any((a) => a.alive && a.y >= height - _playerSize * 3)) {
      onGameOver();
    }

    // Vince se tutti morti
    if (aliens.every((a) => !a.alive)) {
      onGameOver();
    }
  }

  @override
  void onGameOver() {
    if (_gameOver) return; // evita doppie chiamate
    _gameOver = true;
    stop(); // ferma il timer di GameLoop
    notifyListeners(); // forza subito il rebuild dell'UI
  }

  /// Pubblici -----------------------------------------------------------------

  void restart() {
    _initLevel(); // reset di nave, alieni, timer, score, ecc.
    start(); // riavvia il ciclo
    notifyListeners(); // forza subito il rebuild dell'UI
  }
}
