import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Turtle extends BaseEnemy {
  Turtle({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 55,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(28, 18),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(44, 26);

  late final SpriteAnimation _idle2Animation;
  late final SpriteAnimation _spikesInAnimation;
  late final SpriteAnimation _spikesOutAnimation;

  SpriteAnimation get secondaryIdleAnimation => _idle2Animation;
  SpriteAnimation get spikesInAnimation => _spikesInAnimation;
  SpriteAnimation get spikesOutAnimation => _spikesOutAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Turtle/Idle 1 (44x26).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    _idle2Animation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Turtle/Idle 2 (44x26).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Turtle/Hit (44x26).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _spikesInAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Turtle/Spikes in (44x26).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _spikesOutAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Turtle/Spikes out (44x26).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: _idle2Animation,
      EnemyState.hit: hit,
    };
  }
}
