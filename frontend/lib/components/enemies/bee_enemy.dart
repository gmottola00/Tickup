import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Bee extends BaseEnemy {
  Bee({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 100,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(22, 20),
        );

  static const double _stepTime = 0.05;
  static final Vector2 _frameSize = Vector2(36, 34);

  Sprite get bulletSprite => Sprite(
        game.images.fromCache('Enemies/Bee/Bullet.png'),
      );

  Sprite get bulletPiecesSprite => Sprite(
        game.images.fromCache('Enemies/Bee/Bullet Pieces.png'),
      );

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bee/Idle (36x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final attack = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bee/Attack (36x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bee/Hit (36x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: attack,
      EnemyState.hit: hit,
    };
  }
}
