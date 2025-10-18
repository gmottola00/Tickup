import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:tickup/pixel_adventure.dart';

class JumpButton extends SpriteComponent
    with HasGameReference<PixelAdventure>, TapCallbacks {
  JumpButton();

  final margin = 32;
  final buttonSize = 64.0;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));
    size = Vector2.all(buttonSize);
    priority = 10;
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(
      size.x - margin - buttonSize,
      size.y - margin - buttonSize,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.hasJumped = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.hasJumped = false;
    super.onTapUp(event);
  }
}
