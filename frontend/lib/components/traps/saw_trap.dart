import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/traps/base_trap.dart';

class SawTrap extends BaseTrap {
  SawTrap({
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
          moveSpeed: 50,
          defaultPriority: 1,
        );

  @override
  ShapeHitbox? createHitbox() => CircleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Saw/On (38x38).png',
      textureSize: Vector2.all(38),
      stepTime: 0.03,
    );
  }
}
