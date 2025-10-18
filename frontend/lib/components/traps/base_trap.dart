import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/pixel_adventure.dart';

/// Base class for traps that oscillate along one axis (horizontal/vertical).
abstract class BaseTrap extends SpriteAnimationComponent
    with HasGameReference<PixelAdventure> {
  BaseTrap({
    this.isVertical = false,
    this.offNeg = 0,
    this.offPos = 0,
    this.tileSize = 16,
    this.moveSpeed = 50,
    this.defaultPriority = -1,
    super.position,
    super.size,
  });

  final bool isVertical;
  final double offNeg;
  final double offPos;
  final double tileSize;
  final double moveSpeed;
  final int defaultPriority;

  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;

  @override
  Future<void> onLoad() async {
    priority = defaultPriority;
    final hitbox = createHitbox();
    if (hitbox != null) add(hitbox);

    final baseCoordinate = isVertical ? position.y : position.x;
    rangeNeg = baseCoordinate - offNeg * tileSize;
    rangePos = baseCoordinate + offPos * tileSize;

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

  /// Override to provide the trap animation.
  FutureOr<SpriteAnimation> loadAnimation();

  /// Override to customise the hitbox (defaults to a circle).
  ShapeHitbox? createHitbox() => CircleHitbox();

  @override
  void update(double dt) {
    if (isVertical) {
      _moveVertically(dt);
    } else {
      _moveHorizontally(dt);
    }
    super.update(dt);
  }

  void _moveVertically(double dt) {
    if (position.y >= rangePos) {
      moveDirection = -1;
    } else if (position.y <= rangeNeg) {
      moveDirection = 1;
    }
    position.y += moveDirection * moveSpeed * dt;
  }

  void _moveHorizontally(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
    }
    position.x += moveDirection * moveSpeed * dt;
  }
}
