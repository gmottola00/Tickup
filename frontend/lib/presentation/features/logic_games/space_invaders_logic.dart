import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tickup/core/game_engine/game_loop/game_loop.dart';

/// ---------------------------- Modelli base ---------------------------------

class Bullet {
  Bullet({required this.x, required this.y});
  double x;
  double y;
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

/// ------------------------------ Timer mixin --------------------------------

mixin TimedGame on GameLoop {
  double totalTime = 60;
  double timeLeft = 60;

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

/// ------------------------- Logica Space Invaders ---------------------------

class SpaceInvadersLogic extends GameLoop with TimedGame {
  SpaceInvadersLogic({super.tick = const Duration(milliseconds: 16)});

  // ------ dimensioni canvas -------------------------------------------------
  Size _size = Size.zero;
  double get width => _size.width;
  double get height => _size.height;

  void setSize(Size size) {
    if (size != _size) {
      _size = size;
      _initLevel();
    }
  }

  // ------ stato di gioco ----------------------------------------------------
  double playerX = 0;
  final List<Bullet> bullets = [];
  final List<Alien> aliens = [];
  int score = 0;
  bool _gameOver = false;
  bool get gameOver => _gameOver;

  // ------ costanti di movimento --------------------------------------------
  static const double _playerSize = 28;
  static const double _playerSpeed = 260;
  static const double _bulletSpeed = 420;

  // **nuove costanti** per alieni “endless”
  static const double _alienBaseSpeed = 70; // velocità iniziale
  static const double _alienMaxSpeed = 350; // velocità a fine timer
  static const double _spawnStart = 1.2; // intervallo spawn iniziale (s)
  static const double _spawnEnd = 0.25; // intervallo spawn minimo (s)

  // ------ variabili runtime -------------------------------------------------
  double _spawnTimer = 0;
  final Random _rand = Random();

  // --------------------------------------------------------------------------

  void _initLevel() {
    playerX = width / 2;
    bullets.clear();
    aliens.clear();
    score = 0;
    timeLeft = totalTime;
    _spawnTimer = 0;
    _gameOver = false;
  }

  // --------------------------------------------------------------------------
  // INPUT
  // --------------------------------------------------------------------------
  void moveLeft() => playerX = max(_playerSize / 2, playerX - 16);
  void moveRight() => playerX = min(width - _playerSize / 2, playerX + 16);

  void fire() {
    if (_gameOver) return;
    bullets.add(Bullet(x: playerX, y: height - _playerSize));
  }

  // --------------------------------------------------------------------------
  // CICLO DI GIOCO
  // --------------------------------------------------------------------------
  @override
  void update(double dt) {
    if (_gameOver) return;

    // 1. TIMER
    updateTimer(dt);
    if (_gameOver) return;

    // 2. SPAWN alieni a intervallo variabile -------------------------------
    final progress = 1 - timeLeft / totalTime; // 0 → 1
    final currentSpawnInterval =
        max(_spawnEnd, _spawnStart - (_spawnStart - _spawnEnd) * progress);

    _spawnTimer += dt;
    if (_spawnTimer >= currentSpawnInterval) {
      _spawnTimer = 0;
      _spawnAlien();
    }

    // 3. Aggiorna proiettili -------------------------------------------------
    for (final b in bullets) {
      b.y -= _bulletSpeed * dt;
    }
    bullets.removeWhere((b) => b.y < 0);

    // 4. Aggiorna alieni con velocità crescente ----------------------------
    final alienSpeed =
        _alienBaseSpeed + (_alienMaxSpeed - _alienBaseSpeed) * progress;
    for (final a in aliens) {
      if (a.alive) a.y += alienSpeed * dt;
    }

    // 5. Collisioni bullet–alien -------------------------------------------
    for (final b in bullets) {
      for (final a in aliens) {
        if (a.alive && a.toRect().overlaps(b.toRect())) {
          a.alive = false;
          score += 10;
          b.y = -10; // lo rimuoveremo subito dopo
          break;
        }
      }
    }
    bullets.removeWhere((b) => b.y < 0);

    // 6. Game-over se alieno raggiunge la nave -----------------------------
    if (aliens.any((a) => a.alive && a.y >= height - _playerSize * 3)) {
      onGameOver();
    }
  }

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
  void _spawnAlien() {
    // x random con margine di 12 px per lato
    final x = 12 + _rand.nextDouble() * (width - 24);
    aliens.add(Alien(x: x, y: -Alien.size)); // parte appena fuori dallo schermo
  }

  // --------------------------------------------------------------------------
  // GAME-OVER / RESTART
  // --------------------------------------------------------------------------
  @override
  void onGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    stop();
    notifyListeners();
  }

  void restart() {
    _initLevel();
    start();
    notifyListeners();
  }
}
