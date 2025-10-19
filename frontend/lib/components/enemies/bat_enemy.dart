import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Bat extends BaseEnemy {
  Bat({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 90,
          bounceHeight: 220,
          hitboxOffset: Vector2(8, 6),
          hitboxSize: Vector2(28, 18),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(46, 30);

  late final SpriteAnimation _ceilingIn;
  late final SpriteAnimation _ceilingOut;

  SpriteAnimation get ceilingInAnimation => _ceilingIn;
  SpriteAnimation get ceilingOutAnimation => _ceilingOut;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bat/Idle (46x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final flying = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bat/Flying (46x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bat/Hit (46x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _ceilingIn = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bat/Ceiling In (46x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _ceilingOut = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bat/Ceiling Out (46x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: flying,
      EnemyState.hit: hit,
    };
  }
}
