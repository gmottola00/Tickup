import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Radish extends BaseEnemy {
  Radish({
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
          hitboxOffset: Vector2(6, 8),
          hitboxSize: Vector2(18, 24),
        );

  static const double _stepTime = 0.05;
  static final Vector2 _frameSize = Vector2(30, 38);

  late final SpriteAnimation _idle2Animation;

  SpriteAnimation get secondaryIdleAnimation => _idle2Animation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Radish/Idle 1 (30x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    _idle2Animation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Radish/Idle 2 (30x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Radish/Run (30x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Radish/Hit (30x38).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: run,
      EnemyState.hit: hit,
    };
  }
}
