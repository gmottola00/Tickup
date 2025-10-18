import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

class FanTrap extends BaseStaticTrap {
  FanTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Fan/On (24x8).png',
      textureSize: Vector2(24, 8),
      stepTime: 0.08,
    );
  }
}
