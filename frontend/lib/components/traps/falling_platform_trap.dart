import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

class FallingPlatformTrap extends BaseStaticTrap {
  FallingPlatformTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

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
