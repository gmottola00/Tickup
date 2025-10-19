import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_trap.dart';

class SpikesTrap extends BaseTrap {
  SpikesTrap({
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
          useSourceSize: false,
        );

  @override
  ShapeHitbox? createHitbox() => RectangleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    final image = game.images.fromCache('Traps/Spikes/Idle.png');
    final texture = Vector2(image.width.toDouble(), image.height.toDouble());
    if (size.x == 0 || size.y == 0) {
      size
        ..x = texture.x
        ..y = texture.y;
    }
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1,
        textureSize: texture,
        loop: true,
      ),
    );
  }
}
