import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/enemies/base_enemy.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/enemies/trunk_projectile.dart';

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
  
  late final double _attackDuration;
  late final double _projectileSpawnTime;

  static const double _attackCooldown = 2.2;
  static const double _attackRange = 200;
  static const double _verticalTolerance = 45;
  static const double _projectileSpeed = 200;

  double _timeSinceLastAttack = 0;
  double _attackElapsed = 0;
  bool _isAttacking = false;
  bool _projectileSpawned = false;

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
      stepTime: 0.07,
      loop: false,
    );

    _attackAnimation = loadSequencedAnimation(
      images: game.images,
      path: 'Enemies/Trunk/Attack (64x32).png',
      textureSize: _frameSize,
      stepTime: 0.08,
      loop: false,
    );
    
    _attackDuration = _computeDuration(_attackAnimation);
    _projectileSpawnTime = _attackDuration * 0.5;

    return {
      EnemyState.idle: idle,
      EnemyState.run: run,
      EnemyState.attack: _attackAnimation,
      EnemyState.hit: hit,
    };
  }

  double _computeDuration(SpriteAnimation animation) {
    return animation.frames.fold<double>(
      0,
      (total, frame) => total + frame.stepTime,
    );
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      if (_isAttacking) {
        _attackElapsed += dt;
        if (!_projectileSpawned && _attackElapsed >= _projectileSpawnTime) {
          _spawnProjectile();
          _projectileSpawned = true;
        }
        if (_attackElapsed >= _attackDuration) {
          _finishAttack();
        }
      } else {
        _timeSinceLastAttack += dt;
        if (_timeSinceLastAttack >= _attackCooldown && _playerInRange()) {
          _startAttack();
        }
      }
    }
    super.update(dt);
  }

  @override
  void updateState() {
    if (_isAttacking) return;
    super.updateState();
  }

  bool _playerInRange() {
    final playerCenter =
        Vector2(player.x + player.width / 2, player.y + player.height / 2);
    final trunkCenter =
        Vector2(position.x + width / 2, position.y + height / 2);
    final dx = playerCenter.x - trunkCenter.x;
    final dy = (playerCenter.y - trunkCenter.y).abs();
    return dx.abs() <= _attackRange && dy <= _verticalTolerance;
  }

  void _startAttack() {
    _isAttacking = true;
    _attackElapsed = 0;
    _projectileSpawned = false;
    _timeSinceLastAttack = 0;
    final facing = player.x + player.width / 2 >= position.x + width / 2 ? 1 : -1;
    if (scale.x.sign != facing) {
      flipHorizontallyAroundCenter();
    }
    current = EnemyState.attack;
  }

  void _spawnProjectile() {
    final facingRight = scale.x > 0;
    final offsetX = facingRight ? width / 2 + 12 : -width / 2 - 12;
    final spawnPosition = Vector2(position.x + width / 2 + offsetX,
        position.y + height / 2 - 4);
    final projectile = TrunkProjectile(
      position: spawnPosition,
      direction: Vector2(facingRight ? 1 : -1, 0),
      speed: _projectileSpeed,
    );
    parent?.add(projectile);
  }

  void _finishAttack() {
    _isAttacking = false;
    _attackElapsed = 0;
    current = EnemyState.idle;
  }
}
