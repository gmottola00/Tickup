import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

class RockHeadTrap extends BaseStaticTrap {
  RockHeadTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Rock Head/Blink (42x42).png',
      textureSize: Vector2(42, 42),
      stepTime: 0.12,
    );
  }
}
