import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class FatBird extends BaseEnemy {
  FatBird({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 50,
          bounceHeight: 240,
          hitboxOffset: Vector2(8, 8),
          hitboxSize: Vector2(26, 32),
        );

  static const double _stepTime = 0.07;
  static final Vector2 _frameSize = Vector2(40, 48);

  late final SpriteAnimation _groundAnimation;
  late final SpriteAnimation _fallAnimation;

  SpriteAnimation get groundAnimation => _groundAnimation;
  SpriteAnimation get fallAnimation => _fallAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/FatBird/Idle (40x48).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/FatBird/Hit (40x48).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _groundAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/FatBird/Ground (40x48).png',
      textureSize: _frameSize,
      stepTime: 0.06,
    );
    _fallAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/FatBird/Fall (40x48).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: _groundAnimation,
      EnemyState.hit: hit,
    };
  }
}
