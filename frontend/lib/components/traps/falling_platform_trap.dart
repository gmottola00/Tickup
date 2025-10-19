import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/traps/base_trap.dart';

class FallingPlatformTrap extends BaseTrap {
  FallingPlatformTrap({
    super.position,
    super.size,
    bool isVertical = false,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          isVertical: isVertical,
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          moveSpeed: 0,
          defaultPriority: 1,
        );

  @override
  ShapeHitbox? createHitbox() => RectangleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Falling Platforms/On (32x10).png',
      textureSize: Vector2(32, 10),
      stepTime: 0.08,
    );
  }
}
