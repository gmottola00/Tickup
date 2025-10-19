import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/traps/base_trap.dart';

class ArrowTrap extends BaseTrap {
  ArrowTrap({
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
          moveSpeed: isVertical || offNeg != 0 || offPos != 0 ? 45 : 0,
          defaultPriority: 1,
        );

  static final Vector2 _frameSize = Vector2(18, 18);

  late final SpriteAnimation _idle;
  late final SpriteAnimation _hit;

  @override
  ShapeHitbox? createHitbox() => RectangleHitbox();

  @override
  FutureOr<SpriteAnimation> loadAnimation() {
    _idle = loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Arrow/Idle (18x18).png',
      textureSize: _frameSize,
      stepTime: 0.1,
    );
    _hit = loadSequencedAnimation(
      images: game.images,
      path: 'Traps/Arrow/Hit (18x18).png',
      textureSize: _frameSize,
      stepTime: 0.08,
      loop: false,
    );
    return _idle;
  }

  Future<void> trigger() async {
    if (animation == _hit) return;
    animation = _hit;
    await animationTicker?.completed;
    animation = _idle;
  }
}
