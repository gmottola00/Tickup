import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Skull extends BaseEnemy {
  Skull({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 80,
          bounceHeight: 240,
          hitboxOffset: Vector2(10, 10),
          hitboxSize: Vector2(32, 32),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(52, 54);

  late final SpriteAnimation _idle2Animation;
  late final SpriteAnimation _hitWall1Animation;
  late final SpriteAnimation _hitWall2Animation;

  SpriteAnimation get secondaryIdleAnimation => _idle2Animation;
  SpriteAnimation get hitWall1Animation => _hitWall1Animation;
  SpriteAnimation get hitWall2Animation => _hitWall2Animation;

  Sprite get orangeParticleSprite =>
      Sprite(game.images.fromCache('Enemies/Skull/Orange Particle.png'));

  Sprite get redParticleSprite =>
      Sprite(game.images.fromCache('Enemies/Skull/Red Particle.png'));

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Skull/Idle 1 (52x54).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    _idle2Animation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Skull/Idle 2 (52x54).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Skull/Hit (52x54).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _hitWall1Animation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Skull/Hit Wall 1 (52x54).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _hitWall2Animation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Skull/Hit Wall 2 (52x54).png',
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
