import 'dart:async';

import 'package:flame/components.dart';
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
          defaultPriority: -1,
        );

  static const double _stepTime = 0.03;

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Saw/On (38x38).png'),
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: _stepTime,
        textureSize: Vector2.all(38),
      ),
    );
  }
}
