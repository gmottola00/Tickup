import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/pixel_adventure.dart';

/// Base class for traps that stay fixed in place but may have looping animations.
abstract class BaseStaticTrap extends SpriteAnimationComponent
    with HasGameReference<PixelAdventure> {
  BaseStaticTrap({
    this.priorityLayer = 0,
    super.position,
    super.size,
  });

  final int priorityLayer;

  @override
  Future<void> onLoad() async {
    priority = priorityLayer;
    animation = await loadAnimation();
    if (size.x == 0 && size.y == 0) {
      final frameSize = animation?.frames.first.sprite.srcSize;
      if (frameSize != null) {
        size
          ..x = frameSize.x
          ..y = frameSize.y;
      }
    }
    await super.onLoad();
  }

  FutureOr<SpriteAnimation> loadAnimation();
}
