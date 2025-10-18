import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';
import 'package:tickup/components/jump_button.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/components/level.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  final Player player = Player(character: 'Mask Dude');
  late final JoystickComponent joystick;
  bool showControls = true;
  bool playSounds = true;
  double soundVolume = 1.0;
  final List<String> levelNames = ['Level-01', 'Level-01'];
  int currentLevelIndex = 0;
  CameraComponent? _camera;
  Level? _currentLevel;

  @override
  Future<void> onLoad() async {
    await images.loadAllImages();

    await _loadLevel();

    if (showControls) {
      await addJoystick();
      await add(JumpButton());
    }

    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  Future<void> addJoystick() async {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    await add(joystick);
  }

  void updateJoystick() {
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
    currentLevelIndex =
        (currentLevelIndex + 1) % levelNames.length;
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

    await addAll([level, camera]);
  }
}
