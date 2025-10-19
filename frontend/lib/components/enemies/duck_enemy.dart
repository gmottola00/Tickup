import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Duck extends BaseEnemy {
  Duck({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 65,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(24, 26),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(36, 36);

  late final SpriteAnimation _jumpAnimation;
  late final SpriteAnimation _jumpAnticipation;
  late final SpriteAnimation _fallAnimation;

  SpriteAnimation get jumpAnimation => _jumpAnimation;
  SpriteAnimation get jumpAnticipationAnimation => _jumpAnticipation;
  SpriteAnimation get fallAnimation => _fallAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Duck/Idle (36x36).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Duck/Hit (36x36).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _jumpAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Duck/Jump (36x36).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );
    _jumpAnticipation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Duck/Jump Anticipation (36x36).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );
    _fallAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Duck/Fall (36x36).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: _jumpAnimation,
      EnemyState.hit: hit,
    };
  }
}
