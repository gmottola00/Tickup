import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/units/base_unit.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';

enum LancerDirection { 
  up, 
  upRight, 
  right, 
  downRight, 
  down 
}

class Lancer extends BaseUnit {
  Lancer({
    super.position,
    super.size,
    super.unitColor = UnitColor.blue,
    super.maxHealth = 120,
    super.attackDamage = 30,
    super.moveSpeed = 75,
    super.attackRange = 60,
  }) : super(
          unitType: UnitType.lancer,
          hitboxOffset: Vector2(4, 8),
          hitboxSize: Vector2(24, 24),
        );

  static const double _stepTime = 0.15;
  static final Vector2 _frameSize = Vector2(32, 32);

  // Directional attack animations
  late final Map<LancerDirection, SpriteAnimation> _attackAnimations;
  late final Map<LancerDirection, SpriteAnimation> _defenceAnimations;
  
  Map<LancerDirection, SpriteAnimation> get attackAnimations => _attackAnimations;
  Map<LancerDirection, SpriteAnimation> get defenceAnimations => _defenceAnimations;

  bool _isDefending = false;
  LancerDirection _currentDirection = LancerDirection.right;
  
  bool get isDefending => _isDefending;
  LancerDirection get currentDirection => _currentDirection;

  @override
  FutureOr<Map<UnitState, SpriteAnimation>> loadAnimations() {
    final idle = loadUnitAnimation(
      filename: 'Lancer_Idle.png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );

    final run = loadUnitAnimation(
      filename: 'Lancer_Run.png',
      textureSize: _frameSize,
      stepTime: 0.12,
    );

    // Load directional attack animations
    _attackAnimations = {
      LancerDirection.up: loadUnitAnimation(
        filename: 'Lancer_Up_Attack.png',
        textureSize: _frameSize,
        stepTime: 0.1,
        loop: false,
      ),
      LancerDirection.upRight: loadUnitAnimation(
        filename: 'Lancer_UpRight_Attack.png',
        textureSize: _frameSize,
        stepTime: 0.1,
        loop: false,
      ),
      LancerDirection.right: loadUnitAnimation(
        filename: 'Lancer_Right_Attack.png',
        textureSize: _frameSize,
        stepTime: 0.1,
        loop: false,
      ),
      LancerDirection.downRight: loadUnitAnimation(
        filename: 'Lancer_DownRight_Attack.png',
        textureSize: _frameSize,
        stepTime: 0.1,
        loop: false,
      ),
      LancerDirection.down: loadUnitAnimation(
        filename: 'Lancer_Down_Attack.png',
        textureSize: _frameSize,
        stepTime: 0.1,
        loop: false,
      ),
    };

    // Load directional defence animations
    _defenceAnimations = {
      LancerDirection.up: loadUnitAnimation(
        filename: 'Lancer_Up_Defence.png',
        textureSize: _frameSize,
        stepTime: 0.15,
      ),
      LancerDirection.upRight: loadUnitAnimation(
        filename: 'Lancer_UpRight_Defence.png',
        textureSize: _frameSize,
        stepTime: 0.15,
      ),
      LancerDirection.right: loadUnitAnimation(
        filename: 'Lancer_Right_Defence.png',
        textureSize: _frameSize,
        stepTime: 0.15,
      ),
      LancerDirection.downRight: loadUnitAnimation(
        filename: 'Lancer_DownRight_Defence.png',
        textureSize: _frameSize,
        stepTime: 0.15,
      ),
      LancerDirection.down: loadUnitAnimation(
        filename: 'Lancer_Down_Defence.png',
        textureSize: _frameSize,
        stepTime: 0.15,
      ),
    };

    return {
      UnitState.idle: idle,
      UnitState.run: run,
      UnitState.upAttack: _attackAnimations[LancerDirection.up]!,
      UnitState.upRightAttack: _attackAnimations[LancerDirection.upRight]!,
      UnitState.rightAttack: _attackAnimations[LancerDirection.right]!,
      UnitState.downRightAttack: _attackAnimations[LancerDirection.downRight]!,
      UnitState.downAttack: _attackAnimations[LancerDirection.down]!,
      UnitState.upDefence: _defenceAnimations[LancerDirection.up]!,
      UnitState.upRightDefence: _defenceAnimations[LancerDirection.upRight]!,
      UnitState.rightDefence: _defenceAnimations[LancerDirection.right]!,
      UnitState.downRightDefence: _defenceAnimations[LancerDirection.downRight]!,
      UnitState.downDefence: _defenceAnimations[LancerDirection.down]!,
    };
  }

  // Lancer-specific methods
  LancerDirection _calculateDirection(Vector2 target) {
    final direction = (target - position).normalized();
    final angle = direction.angleToSigned(Vector2(1, 0));
    final degrees = angle * 180 / math.pi;
    
    // Convert angle to direction
    if (degrees >= -22.5 && degrees <= 22.5) {
      return LancerDirection.right;
    } else if (degrees > 22.5 && degrees <= 67.5) {
      return LancerDirection.downRight;
    } else if (degrees > 67.5 && degrees <= 112.5) {
      return LancerDirection.down;
    } else if (degrees > 112.5 && degrees <= 157.5) {
      return LancerDirection.downRight; // Mirror for left side
    } else if ((degrees > 157.5 && degrees <= 180) || (degrees >= -180 && degrees <= -157.5)) {
      return LancerDirection.right; // Mirror for left side
    } else if (degrees >= -157.5 && degrees <= -112.5) {
      return LancerDirection.upRight; // Mirror for left side  
    } else if (degrees >= -112.5 && degrees <= -67.5) {
      return LancerDirection.up;
    } else { // degrees >= -67.5 && degrees <= -22.5
      return LancerDirection.upRight;
    }
  }

  UnitState _getAttackStateFromDirection(LancerDirection direction) {
    switch (direction) {
      case LancerDirection.up:
        return UnitState.upAttack;
      case LancerDirection.upRight:
        return UnitState.upRightAttack;
      case LancerDirection.right:
        return UnitState.rightAttack;
      case LancerDirection.downRight:
        return UnitState.downRightAttack;
      case LancerDirection.down:
        return UnitState.downAttack;
    }
  }

  UnitState _getDefenceStateFromDirection(LancerDirection direction) {
    switch (direction) {
      case LancerDirection.up:
        return UnitState.upDefence;
      case LancerDirection.upRight:
        return UnitState.upRightDefence;
      case LancerDirection.right:
        return UnitState.rightDefence;
      case LancerDirection.downRight:
        return UnitState.downRightDefence;
      case LancerDirection.down:
        return UnitState.downDefence;
    }
  }

  Future<void> thrustAt(Vector2 target) async {
    if (!canAttack()) return;

    _currentDirection = _calculateDirection(target);
    final attackState = _getAttackStateFromDirection(_currentDirection);
    
    // Handle sprite flipping for left-side attacks
    final direction = (target - position).normalized();
    if (direction.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (direction.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    
    await startAttack(attackState);
  }

  void startDefence(Vector2? threatDirection) {
    if (isDead || isAttacking) return;
    
    if (threatDirection != null) {
      _currentDirection = _calculateDirection(threatDirection);
    }
    
    _isDefending = true;
    final defenceState = _getDefenceStateFromDirection(_currentDirection);
    current = defenceState;
  }

  void stopDefence() {
    if (!_isDefending) return;
    
    _isDefending = false;
    current = UnitState.idle;
  }

  Future<void> chargeAttack(Vector2 target) async {
    if (!canAttack()) return;
    
    // Move towards target while attacking
    final direction = (target - position).normalized();
    final chargeDistance = 40.0;
    final chargeTarget = position + direction * chargeDistance;
    
    _currentDirection = _calculateDirection(target);
    final attackState = _getAttackStateFromDirection(_currentDirection);
    
    current = attackState;
    
    // Animate charge movement during attack
    final chargeDuration = 0.3;
    final startPos = position.clone();
    var elapsed = 0.0;
    
    // Simple lerp function for charge movement
    void updateChargePosition(double progress) {
      final lerpedX = startPos.x + (chargeTarget.x - startPos.x) * progress;
      final lerpedY = startPos.y + (chargeTarget.y - startPos.y) * progress;
      position.setValues(lerpedX, lerpedY);
    }
    
    // Use a simple async approach instead of Timer.periodic
    while (elapsed < chargeDuration) {
      await Future.delayed(const Duration(milliseconds: 16));
      elapsed += 0.016;
      final progress = (elapsed / chargeDuration).clamp(0.0, 1.0);
      updateChargePosition(progress);
    }
    
    await animationTicker?.completed;
    current = UnitState.idle;
  }

  @override
  void takeDamage(double damage) {
    // Reduce damage if defending from the correct direction
    var actualDamage = damage;
    if (_isDefending) {
      // TODO: Implement directional damage reduction based on attack direction
      actualDamage = damage * 0.4; // Generic reduction for now
    }
    super.takeDamage(actualDamage);
  }

  @override
  void updateBehavior(double dt) {
    super.updateBehavior(dt);
    
    // Add lancer-specific behavior here
    // For example: formation fighting, phalanx tactics, etc.
  }
}