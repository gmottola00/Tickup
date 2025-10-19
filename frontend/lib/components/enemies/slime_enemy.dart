import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Slime extends BaseEnemy {
  Slime({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 60,
          bounceHeight: 200,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(28, 18),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(44, 30);

  late final SpriteAnimation _particleAnimation;

  SpriteAnimation get particleAnimation => _particleAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idleRun = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Slime/Idle-Run (44x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Slime/Hit (44x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _particleAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Slime/Particles (62x16).png',
      textureSize: Vector2(62, 16),
      stepTime: 0.05,
    );

    return {
      EnemyState.idle: idleRun,
      EnemyState.run: idleRun,
      EnemyState.hit: hit,
    };
  }
}
