import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Mushroom extends BaseEnemy {
  Mushroom({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 70,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 4),
          hitboxSize: Vector2(20, 20),
        );

  static const double _stepTime = 0.05;
  static final Vector2 _frameSize = Vector2(32, 32);

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Mushroom/Idle (32x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Mushroom/Run (32x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Mushroom/Hit.png',
      textureSize: _frameSize,
      stepTime: 0.06,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: run,
      EnemyState.hit: hit,
    };
  }
}
