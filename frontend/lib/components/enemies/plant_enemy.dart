import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Plant extends BaseEnemy {
  Plant({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 0,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(28, 30),
        );

  static const double _stepTime = 0.07;
  static final Vector2 _frameSize = Vector2(44, 42);

  Sprite get bulletSprite => Sprite(
        game.images.fromCache('Enemies/Plant/Bullet.png'),
      );

  Sprite get bulletPiecesSprite => Sprite(
        game.images.fromCache('Enemies/Plant/Bullet Pieces.png'),
      );

  late final SpriteAnimation _attackAnimation;

  SpriteAnimation get attackAnimation => _attackAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Plant/Idle (44x42).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Plant/Hit (44x42).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _attackAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Plant/Attack (44x42).png',
      textureSize: _frameSize,
      stepTime: 0.06,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: idle,
      EnemyState.hit: hit,
    };
  }
}
