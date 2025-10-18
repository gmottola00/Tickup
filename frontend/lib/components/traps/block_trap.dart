import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/base_static_trap.dart';

class BlockTrap extends BaseStaticTrap {
  BlockTrap({
    super.position,
    super.size,
    int priority = -1,
  }) : super(priorityLayer: priority);

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    final image = game.images.fromCache('Traps/Blocks/Idle.png');
    final frameSize = Vector2(image.width.toDouble(), image.height.toDouble());
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1,
        textureSize: frameSize,
      ),
    );
  }
}
