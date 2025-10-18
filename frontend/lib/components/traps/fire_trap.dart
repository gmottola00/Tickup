import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

class FireTrap extends BaseStaticTrap {
  FireTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

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
