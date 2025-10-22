import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/units/base_unit.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';
import 'package:tickup/pixel_adventure.dart';

class Arrow extends SpriteComponent with HasGameReference<PixelAdventure> {
  Arrow({
    required super.position,
    required this.direction,
    required this.damage,
    this.speed = 300,
    this.maxRange = 400,s
  }) : super(anchor: Anchor.center);

  final Vector2 direction;
  final double damage;
  final double speed;
  final double maxRange;
  
  late final Vector2 _startPosition;
  late final Vector2 _normalizedDirection;
  
  @override
  Future<void> onLoad() async {
    _startPosition = position.clone();
    _normalizedDirection = direction.normalized();
    
    // Load arrow sprite from the same directory as the archer
    sprite = Sprite(game.images.fromCache('TinySwords/Units/Blue Units/Archer/Arrow.png'));
    size = Vector2(16, 4); // Adjust size as needed
    
    // Rotate arrow to match direction
    angle = _normalizedDirection.angleToSigned(Vector2(1, 0));
    
    await super.onLoad();
  }
  
  @override
  void update(double dt) {
    position += _normalizedDirection * speed * dt;
    
    // Remove arrow if it traveled too far
    if (position.distanceTo(_startPosition) > maxRange) {
      removeFromParent();
    }
    
    super.update(dt);
  }
}

class Archer extends BaseUnit {
  Archer({
    super.position,
    super.size,
    super.unitColor = UnitColor.blue,
    super.maxHealth = 80,
    super.attackDamage = 25,
    super.moveSpeed = 90,
    super.attackRange = 200,
  }) : super(
          unitType: UnitType.archer,
          hitboxOffset: Vector2(4, 8),
          hitboxSize: Vector2(24, 24),
        );

  static const double _stepTime = 0.15;
  static final Vector2 _frameSize = Vector2(32, 32);

  late final SpriteAnimation _shootAnimation;
  SpriteAnimation get shootAnimation => _shootAnimation;

  Vector2? _target;
  double _arrowSpeed = 300;
  int _arrowCount = 1;

  @override
  FutureOr<Map<UnitState, SpriteAnimation>> loadAnimations() {
    final idle = loadUnitAnimation(
      filename: 'Archer_Idle.png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );

    final run = loadUnitAnimation(
      filename: 'Archer_Run.png',
      textureSize: _frameSize,
      stepTime: 0.12,
    );

    _shootAnimation = loadUnitAnimation(
      filename: 'Archer_Shoot.png',
      textureSize: _frameSize,
      stepTime: 0.1,
      loop: false,
    );

    return {
      UnitState.idle: idle,
      UnitState.run: run,
      UnitState.shoot: _shootAnimation,
    };
  }

  // Archer-specific methods
  Future<void> shootAt(Vector2 target) async {
    if (!canAttack()) return;

    _target = target.clone();
    await startAttack(UnitState.shoot);
    
    // Spawn arrow during animation
    _spawnArrow();
  }

  Future<void> shootInDirection(Vector2 direction) async {
    if (!canAttack()) return;

    _target = position + direction.normalized() * attackRange;
    await startAttack(UnitState.shoot);
    
    // Spawn arrow during animation
    _spawnArrow();
  }

  void _spawnArrow() {
    if (_target == null) return;

    final direction = _target! - position;
    direction.y -= 16; // Adjust for archer height
    
    // Create arrow(s)
    for (int i = 0; i < _arrowCount; i++) {
      final spreadAngle = (_arrowCount > 1) ? (i - _arrowCount / 2) * 0.2 : 0;
      final adjustedDirection = direction.clone();
      
      if (spreadAngle != 0) {
        final cos = math.cos(spreadAngle);
        final sin = math.sin(spreadAngle);
        final x = adjustedDirection.x * cos - adjustedDirection.y * sin;
        final y = adjustedDirection.x * sin + adjustedDirection.y * cos;
        adjustedDirection.setValues(x, y);
      }

      final arrow = Arrow(
        position: position + Vector2(0, -16), // Spawn from archer position
        direction: adjustedDirection,
        damage: attackDamage,
        speed: _arrowSpeed,
        maxRange: attackRange,
      );

      parent?.add(arrow);
    }
    
    _target = null;
  }

  // Archer upgrades/abilities
  void upgradeMultiShot(int arrowCount) {
    _arrowCount = arrowCount.clamp(1, 5);
  }

  void upgradeArrowSpeed(double speed) {
    _arrowSpeed = speed;
  }

  bool isInRange(Vector2 target) {
    return position.distanceTo(target) <= attackRange;
  }

  @override
  void updateBehavior(double dt) {
    super.updateBehavior(dt);
    
    // Add archer-specific behavior here
    // For example: kiting behavior, auto-targeting, etc.
  }
}