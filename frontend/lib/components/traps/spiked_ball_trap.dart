import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_trap.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class SpikedBallTrap extends BaseTrap {
  SpikedBallTrap({
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
          moveSpeed: 45,
          defaultPriority: 1,
        );

  @override
  ShapeHitbox? createHitbox() => CircleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Spiked Ball/Spiked Ball.png',
      textureSize: Vector2.all(32),
      stepTime: 0.1,
    );
  }
}
