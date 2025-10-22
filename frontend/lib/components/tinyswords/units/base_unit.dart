import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:meta/meta.dart';
import 'package:tickup/components/shared/sprite_animation_utils.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';
import 'package:tickup/pixel_adventure.dart';

abstract class BaseUnit extends SpriteAnimationGroupComponent<UnitState>
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  BaseUnit({
    super.position,
    super.size,
    required this.unitColor,
    required this.unitType,
    this.maxHealth = 100,
    this.attackDamage = 20,
    this.moveSpeed = 80,
    this.attackRange = 50,
    Vector2? hitboxSize,
    Vector2? hitboxOffset,
  })  : hitboxSize = hitboxSize ?? Vector2.all(16),
        hitboxOffset = hitboxOffset ?? Vector2.zero(),
        _currentHealth = maxHealth;

  final UnitColor unitColor;
  final UnitType unitType;
  final double maxHealth;
  final double attackDamage;
  final double moveSpeed;
  final double attackRange;
  final Vector2 hitboxSize;
  final Vector2 hitboxOffset;

  @protected
  final Vector2 velocity = Vector2.zero();
  
  double _currentHealth;
  bool _isDead = false;
  bool _isAttacking = false;
  double _lastAttackTime = 0;
  static const double _attackCooldown = 1.0;

  // Getters
  double get currentHealth => _currentHealth;
  bool get isDead => _isDead;
  bool get isAttacking => _isAttacking;
  double get healthPercentage => _currentHealth / maxHealth;
  
  // Directory paths for animations
  String get colorName => _getColorName(unitColor);
  String get unitTypeName => _getUnitTypeName(unitType);
  String get basePath => 'TinySwords/Units/$colorName Units/$unitTypeName';

  String _getColorName(UnitColor color) {
    switch (color) {
      case UnitColor.blue:
        return 'Blue';
      case UnitColor.red:
        return 'Red';
      case UnitColor.black:
        return 'Black';
      case UnitColor.yellow:
        return 'Yellow';
    }
  }

  String _getUnitTypeName(UnitType type) {
    switch (type) {
      case UnitType.warrior:
        return 'Warrior';
      case UnitType.archer:
        return 'Archer';
      case UnitType.monk:
        return 'Monk';
      case UnitType.lancer:
        return 'Lancer';
    }
  }

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        position: hitboxOffset,
        size: hitboxSize,
      ),
    );
    animations = await loadAnimations();
    current = UnitState.idle;
    if (size.x == 0 && size.y == 0) {
      final frameSize = animations?[UnitState.idle]?.frames.first.sprite.srcSize;
      if (frameSize != null) {
        size
          ..x = frameSize.x
          ..y = frameSize.y;
      }
    }
    await super.onLoad();
  }

  @protected
  FutureOr<Map<UnitState, SpriteAnimation>> loadAnimations();

  @override
  void update(double dt) {
    if (!_isDead) {
      updateBehavior(dt);
      movement(dt);
    }
    super.update(dt);
  }

  @protected
  void updateBehavior(double dt) {
    _lastAttackTime += dt;
    
    if (!_isAttacking) {
      updateState();
    }
  }

  @protected
  void movement(double dt) {
    // Basic movement - can be overridden by subclasses
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
  }

  @protected
  void updateState() {
    // Basic state management - can be overridden by subclasses
    current = velocity.length > 0 ? UnitState.run : UnitState.idle;
    
    // Handle sprite flipping based on movement direction
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
  }

  // Combat methods
  void takeDamage(double damage) {
    if (_isDead) return;
    
    _currentHealth = (_currentHealth - damage).clamp(0, maxHealth);
    
    if (_currentHealth <= 0) {
      _die();
    }
  }

  void heal(double amount) {
    if (_isDead) return;
    
    _currentHealth = (_currentHealth + amount).clamp(0, maxHealth);
  }

  bool canAttack() {
    return !_isDead && !_isAttacking && _lastAttackTime >= _attackCooldown;
  }

  @protected
  Future<void> startAttack(UnitState attackState) async {
    if (!canAttack()) return;
    
    _isAttacking = true;
    _lastAttackTime = 0;
    current = attackState;
    
    // Wait for animation to complete
    await animationTicker?.completed;
    
    _isAttacking = false;
    current = UnitState.idle;
  }

  void _die() {
    _isDead = true;
    // Add death animation logic here if needed
    // For now, just remove the unit
    removeFromParent();
  }

  // Utility methods for loading animations
  @protected
  SpriteAnimation loadUnitAnimation({
    required String filename,
    required Vector2 textureSize,
    double stepTime = 0.1,
    bool loop = true,
  }) {
    return loadSequencedAnimation(
      images: game.images,
      path: '$basePath/$filename',
      textureSize: textureSize,
      stepTime: stepTime,
      loop: loop,
    );
  }
}