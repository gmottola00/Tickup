import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';

enum RockEnemyVariant { rock1, rock2, rock3 }

class RockEnemy extends BaseEnemy {
  RockEnemy({
    super.position,
    super.size,
    this.variant = RockEnemyVariant.rock1,
    double offNeg = 0,
    double offPos = 0,
  }) : super(
          offNeg: offNeg,
          offPos: offPos,
          tileSize: 16,
          runSpeed: _config[variant]!.runSpeed,
          bounceHeight: 220,
          hitboxOffset: _config[variant]!.hitboxOffset,
          hitboxSize: _config[variant]!.hitboxSize,
        );

  final RockEnemyVariant variant;

  static const double _stepTime = 0.05;

  static final Map<RockEnemyVariant, _RockConfig> _config = {
    RockEnemyVariant.rock1: _RockConfig(
      prefix: 'Rock1',
      frameSize: Vector2(38, 34),
      hitboxSize: Vector2(26, 24),
      hitboxOffset: Vector2(6, 8),
      runSpeed: 60,
    ),
    RockEnemyVariant.rock2: _RockConfig(
      prefix: 'Rock2',
      frameSize: Vector2(32, 28),
      hitboxSize: Vector2(22, 20),
      hitboxOffset: Vector2(5, 6),
      runSpeed: 70,
    ),
    RockEnemyVariant.rock3: _RockConfig(
      prefix: 'Rock3',
      frameSize: Vector2(22, 18),
      hitboxSize: Vector2(16, 14),
      hitboxOffset: Vector2(3, 4),
      runSpeed: 80,
    ),
  };

  _RockConfig get _current => _config[variant]!;

  @override
  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations() {
    final prefix = _current.prefix;
    final idle = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rocks/${prefix}_Idle (${_current.frameSize.x.toInt()}x${_current.frameSize.y.toInt()}).png',
      textureSize: _current.frameSize,
      stepTime: _stepTime,
    );
    final run = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rocks/${prefix}_Run (${_current.frameSize.x.toInt()}x${_current.frameSize.y.toInt()}).png',
      textureSize: _current.frameSize,
      stepTime: _stepTime,
    );
    final hit = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Rocks/${prefix}_Hit${prefix == 'Rock1' ? '' : ' (${_current.frameSize.x.toInt()}x${_current.frameSize.y.toInt()})'}.png',
      textureSize: _current.frameSize,
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

class _RockConfig {
  const _RockConfig({
    required this.prefix,
    required this.frameSize,
    required this.hitboxSize,
    required this.hitboxOffset,
    required this.runSpeed,
  });

  final String prefix;
  final Vector2 frameSize;
  final Vector2 hitboxSize;
  final Vector2 hitboxOffset;
  final double runSpeed;
}
