import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Trunk extends BaseEnemy {
  Trunk({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 60,
          bounceHeight: 220,
          hitboxOffset: Vector2(10, 6),
          hitboxSize: Vector2(44, 20),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(64, 32);

  late final SpriteAnimation _attackAnimation;

  SpriteAnimation get attackAnimation => _attackAnimation;

  Sprite get bulletSprite => Sprite(
        game.images.fromCache('Enemies/Trunk/Bullet.png'),
      );

  Sprite get bulletPiecesSprite => Sprite(
        game.images.fromCache('Enemies/Trunk/Bullet Pieces.png'),
      );

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Trunk/Idle (64x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Trunk/Run (64x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Trunk/Hit (64x32).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _attackAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Trunk/Attack (64x32).png',
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
