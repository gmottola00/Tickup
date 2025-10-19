import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/traps/base_trap.dart';

class FireTrap extends BaseTrap {
  FireTrap({
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
      path: 'Traps/Fire/On (16x32).png',
      textureSize: Vector2(16, 32),
      stepTime: 0.12,
    );
  }
}
