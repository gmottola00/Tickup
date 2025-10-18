import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

class SpikeHeadTrap extends BaseStaticTrap {
  SpikeHeadTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Spike Head/Blink (54x52).png',
      textureSize: Vector2(54, 52),
      stepTime: 0.12,
    );
  }
}
