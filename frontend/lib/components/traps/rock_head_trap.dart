import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/traps/base_trap.dart';

class RockHeadTrap extends BaseTrap {
  RockHeadTrap({
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
          moveSpeed: isVertical || offNeg != 0 || offPos != 0 ? 40 : 0,
          defaultPriority: 1,
        );

  @override
  ShapeHitbox? createHitbox() => RectangleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Rock Head/Idle.png',
      textureSize: Vector2(42, 42),
      stepTime: 0.12,
    );
  }
}
