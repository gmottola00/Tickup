import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class BlueBird extends BaseEnemy {
  BlueBird({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 110,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(22, 18),
        );

  static const double _stepTime = 0.05;
  static final Vector2 _frameSize = Vector2(32, 32);

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final flying = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/BlueBird/Flying (32x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/BlueBird/Hit (32x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: flying,
      EnemyState.run: flying,
      EnemyState.hit: hit,
    };
  }
}
