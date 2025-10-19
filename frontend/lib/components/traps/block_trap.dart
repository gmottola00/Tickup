import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_trap.dart';

class BlockTrap extends BaseTrap {
  BlockTrap({
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
          moveSpeed: 0,
          defaultPriority: 1,
        );

  @override
  ShapeHitbox? createHitbox() => RectangleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    final image = game.images.fromCache('Traps/Blocks/Idle.png');
    final texture = Vector2(image.width.toDouble(), image.height.toDouble());
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1,
        textureSize: texture,
      ),
    );
  }
}
