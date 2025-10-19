import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Ghost extends BaseEnemy {
  Ghost({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 60,
          bounceHeight: 200,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(24, 18),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(44, 30);

  late final SpriteAnimation _appearAnimation;
  late final SpriteAnimation _disappearAnimation;
  SpriteAnimation get appearAnimation => _appearAnimation;
  SpriteAnimation get disappearAnimation => _disappearAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Ghost/Idle (44x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Ghost/Hit (44x30).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _appearAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Ghost/Appear (44x30).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );
    _disappearAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Ghost/Desappear (44x30).png',
      textureSize: _frameSize,
      stepTime: 0.05,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: idle,
      EnemyState.hit: hit,
    };
  }
}
