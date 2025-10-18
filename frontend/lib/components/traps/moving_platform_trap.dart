import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_trap.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';

enum MovingPlatformSkin { grey, brown }

class MovingPlatformTrap extends BaseTrap {
  MovingPlatformTrap({
    super.position,
    super.size,
    bool isVertical = false,
    double offNeg = 0,
    double offPos = 0,
    this.skin = MovingPlatformSkin.grey,
  }) : super(
          isVertical: isVertical,
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          moveSpeed: 35,
          defaultPriority: -1,
        );

  final MovingPlatformSkin skin;

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    final prefix = skin == MovingPlatformSkin.grey ? 'Grey' : 'Brown';
    return loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Platforms/$prefix On (32x8).png',
      textureSize: Vector2(32, 8),
      stepTime: 0.08,
    );
  }
}
