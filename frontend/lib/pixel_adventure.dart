import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:tickup/components/jump_button.dart';
import 'package:tickup/components/level.dart';
import 'package:tickup/components/player.dart';

enum GameStatus { loading, playing, timeUp }

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  static const List<String> _defaultLevels = ['Level-01', 'Level-02'];
  static const int defaultFruitScore = 100;
  static const int defaultEnemyScore = 250;

  PixelAdventure({
    List<String>? levels,
    int initialLevelIndex = 0,
    Player? player,
    Map<String, double>? levelTimeLimits,
    this.defaultTimeLimit = 120,
    this.fruitScoreValue = defaultFruitScore,
    this.enemyScoreValue = defaultEnemyScore,
    this.showControls = true,
    this.playSounds = true,
    this.soundVolume = 1.0,
    this.onTimeUp,
  })  : levelNames = List.unmodifiable(levels ?? _defaultLevels),
        player = player ?? Player(character: 'Mask Dude'),
        levelTimeLimits = UnmodifiableMapView(levelTimeLimits ?? const {}),
        currentLevelIndex = _clampIndex(initialLevelIndex, levels ?? _defaultLevels);

  @override
  Color backgroundColor() => const Color(0xFF211F30);

  final Player player;
  final List<String> levelNames;
  final Map<String, double> levelTimeLimits;
  final double defaultTimeLimit;
  final int fruitScoreValue;
  final int enemyScoreValue;
  final bool showControls;
  bool playSounds;
  double soundVolume;
  int currentLevelIndex;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> timeNotifier = ValueNotifier<double>(0);
  final ValueNotifier<GameStatus> statusNotifier =
      ValueNotifier<GameStatus>(GameStatus.loading);

  int score = 0;
  double _remainingTime = 0;
  GameStatus _status = GameStatus.loading;

  JoystickComponent? _joystick;
  CameraComponent? _camera;
  Level? _currentLevel;
  final VoidCallback? onTimeUp;

  bool get isGameOver => _status == GameStatus.timeUp;
  double get remainingTime => _remainingTime;
  int get currentScore => score;

  @override
  Future<void> onLoad() async {
    assert(levelNames.isNotEmpty, 'PixelAdventure requires at least one level.');
    await images.loadAllImages();

    await _loadLevel();

    if (showControls) {
      await _addJoystick();
      await add(JumpButton());
    }

    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (_status == GameStatus.playing) {
      if (showControls) {
        _updateJoystick();
      }
      _advanceTimer(dt);
    }
    super.update(dt);
  }

  Future<void> _addJoystick() async {
    final joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Knob.png')),
      ),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    _joystick = joystick;
    await add(joystick);
  }

  void _updateJoystick() {
    final joystick = _joystick;
    if (joystick == null) {
      return;
    }
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  Future<void> loadNextLevel() async {
    if (levelNames.isEmpty) return;
    currentLevelIndex = (currentLevelIndex + 1) % levelNames.length;
    await _loadLevel();
  }

  Future<void> startLevel(String levelName) async {
    final index = levelNames.indexOf(levelName);
    if (index == -1) {
      return;
    }
    currentLevelIndex = index;
    await _loadLevel();
  }

  Future<void> _loadLevel() async {
    _camera?.removeFromParent();
    _currentLevel?.removeFromParent();

    final level = Level(
      player: player,
      levelName: levelNames[currentLevelIndex],
    );

    final camera = CameraComponent.withFixedResolution(
      world: level,
      width: 640,
      height: 360,
    )..viewfinder.anchor = Anchor.topLeft;

    _currentLevel = level;
    _camera = camera;

    await addAll([camera, level]);
    _resetForNewLevel(levelNames[currentLevelIndex]);
  }

  static int _clampIndex(int requested, List<String> maybeLevels) {
    final levels = maybeLevels.isEmpty ? _defaultLevels : maybeLevels;
    if (levels.isEmpty) {
      return 0;
    }
    final maxIndex = levels.length - 1;
    return math.max(math.min(requested, maxIndex), 0);
  }

  static List<String> get defaultLevels => List.unmodifiable(_defaultLevels);

  void addScore(int delta) {
    if (delta == 0 || _status != GameStatus.playing) {
      return;
    }
    score = math.max(0, score + delta);
    scoreNotifier.value = score;
  }

  void _advanceTimer(double dt) {
    if (_remainingTime <= 0) {
      _handleTimeExpired();
      return;
    }
    _remainingTime = math.max(0, _remainingTime - dt);
    timeNotifier.value = _remainingTime;
    if (_remainingTime <= 0) {
      _handleTimeExpired();
    }
  }

  void _handleTimeExpired() {
    if (_status == GameStatus.timeUp) {
      return;
    }
    _remainingTime = 0;
    timeNotifier.value = 0;
    player.horizontalMovement = 0;
    player.hasJumped = false;
    player.velocity = Vector2.zero();
    player.gotHit = true;
    _setStatus(GameStatus.timeUp);
    onTimeUp?.call();
  }

  void _resetForNewLevel(String levelName) {
    final timeLimit = levelTimeLimits[levelName] ?? defaultTimeLimit;
    _remainingTime = math.max(0, timeLimit);
    timeNotifier.value = _remainingTime;
    player
      ..horizontalMovement = 0
      ..hasJumped = false
      ..gotHit = false
      ..velocity = Vector2.zero();
    _setStatus(GameStatus.playing);
  }

  void _setStatus(GameStatus status) {
    if (_status == status) return;
    _status = status;
    statusNotifier.value = status;
  }

  @override
  void onRemove() {
    scoreNotifier.dispose();
    timeNotifier.dispose();
    statusNotifier.dispose();
    super.onRemove();
  }
}
