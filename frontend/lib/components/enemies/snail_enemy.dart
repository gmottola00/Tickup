import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Snail extends BaseEnemy {
  Snail({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 40,
          bounceHeight: 220,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(24, 18),
        );

  static const double _stepTime = 0.06;
  static final Vector2 _frameSize = Vector2(38, 24);

  late final SpriteAnimation _shellIdleAnimation;
  late final SpriteAnimation _shellTopHitAnimation;
  late final SpriteAnimation _shellWallHitAnimation;

  SpriteAnimation get shellIdleAnimation => _shellIdleAnimation;
  SpriteAnimation get shellTopHitAnimation => _shellTopHitAnimation;
  SpriteAnimation get shellWallHitAnimation => _shellWallHitAnimation;

  Sprite get snailWithoutShellSprite =>
      Sprite(game.images.fromCache('Enemies/Snail/Snail without shell.png'));

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Idle (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final walk = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Walk (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Hit (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    _shellIdleAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Shell Idle (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    _shellTopHitAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Shell Top Hit (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _shellWallHitAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Snail/Shell Wall Hit (38x24).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: idle,
      EnemyState.run: walk,
      EnemyState.hit: hit,
    };
  }
}
