import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Chameleon extends BaseEnemy {
  Chameleon({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 70,
          bounceHeight: 240,
          hitboxOffset: Vector2(12, 6),
          hitboxSize: Vector2(52, 24),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(84, 38);

  late final SpriteAnimation _attackAnimation;

  SpriteAnimation get attackAnimation => _attackAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chameleon/Idle (84x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chameleon/Run (84x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chameleon/Hit (84x38).png',
      textureSize: _frameSize,
      stepTime: 0.07,
      loop: false,
    );

    _attackAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chameleon/Attack (84x38).png',
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
