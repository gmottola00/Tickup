import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

class Rino extends BaseEnemy {
  Rino({
    super.position,
    super.size,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: 140,
          bounceHeight: 240,
          hitboxOffset: Vector2(8, 6),
          hitboxSize: Vector2(36, 22),
        );

  static const double _stepTime = 0.05;
  static final Vector2 _frameSize = Vector2(52, 34);

  late final SpriteAnimation _hitWallAnimation;

  SpriteAnimation get hitWallAnimation => _hitWallAnimation;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rino/Idle (52x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rino/Run (52x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rino/Hit (52x34).png',
      textureSize: _frameSize,
      stepTime: _stepTime,
      loop: false,
    );
    _hitWallAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rino/Hit Wall (52x34).png',
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
