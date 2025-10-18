import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:tickup/components/base_enemy.dart';

class AngryPig extends BaseEnemy {
  AngryPig({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 70,
          bounceHeight: 240,
          hitboxOffset: Vector2(6, 6),
          hitboxSize: Vector2(24, 22),
        );

  static const double stepTime = 0.06;
  static final Vector2 textureSize = Vector2(36, 30);

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    _idleAnimation = _spriteAnimation('Idle (36x30).png', 9);
    _runAnimation = _spriteAnimation('Run (36x30).png', 12);
    _hitAnimation = _spriteAnimation('Hit 1 (36x30).png', 5)..loop = false;

    return {
      EnemyState.idle: _idleAnimation,
      EnemyState.run: _runAnimation,
      EnemyState.hit: _hitAnimation,
    };
  }

  SpriteAnimation _spriteAnimation(String fileName, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/AngryPig/$fileName'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
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
