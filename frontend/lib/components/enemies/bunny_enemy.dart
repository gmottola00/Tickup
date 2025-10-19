import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Bunny extends BaseEnemy {
  Bunny({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 120,
          bounceHeight: 260,
          hitboxOffset: Vector2(8, 6),
          hitboxSize: Vector2(20, 30),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(34, 44);

  Sprite get jumpSprite => Sprite(
        game.images.fromCache('Enemies/Bunny/Jump.png'),
      );

  Sprite get fallSprite => Sprite(
        game.images.fromCache('Enemies/Bunny/Fall.png'),
      );

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bunny/Idle (34x44).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bunny/Run (34x44).png',
      textureSize: _frameSize,
      stepTime: 0.05,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Bunny/Hit (34x44).png',
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
