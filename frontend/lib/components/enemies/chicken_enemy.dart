import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Chicken extends BaseEnemy {
  Chicken({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 80,
          bounceHeight: 260,
          hitboxOffset: Vector2(4, 6),
          hitboxSize: Vector2(24, 26),
        );

  static const double stepTime = 0.05;
  static final Vector2 textureSize = Vector2(32, 34);

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    _idleAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chicken/Idle (32x34).png',
      textureSize: textureSize,
      stepTime: stepTime,
    );
    _runAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chicken/Run (32x34).png',
      textureSize: textureSize,
      stepTime: stepTime,
    );
    _hitAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Chicken/Hit (32x34).png',
      textureSize: textureSize,
      stepTime: stepTime,
      loop: false,
    );

    return {
      EnemyState.idle: _idleAnimation,
      EnemyState.run: _runAnimation,
      EnemyState.hit: _hitAnimation,
    };
  }

  @override
  Future<void> onStomped() async {
    if (game.playSounds) {
      FlameAudio.play('bounce.wav', volume: game.soundVolume);
    }
    game.addScore(game.enemyScoreValue);
    await super.onStomped();
  }
}
