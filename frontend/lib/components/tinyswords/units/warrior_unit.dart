import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/units/base_unit.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';

class Warrior extends BaseUnit {
  Warrior({
    super.position,
    super.size,
    super.unitColor = UnitColor.blue,
    super.maxHealth = 150,
    super.attackDamage = 35,
    super.moveSpeed = 70,
    super.attackRange = 40,
  }) : super(
          unitType: UnitType.warrior,
          hitboxOffset: Vector2(4, 8),
          hitboxSize: Vector2(24, 24),
        );

  static const double _stepTime = 0.15;
  static final Vector2 _frameSize = Vector2(32, 32);

  late final SpriteAnimation _attack1Animation;
  late final SpriteAnimation _attack2Animation;
  late final SpriteAnimation _guardAnimation;

  SpriteAnimation get attack1Animation => _attack1Animation;
  SpriteAnimation get attack2Animation => _attack2Animation;
  SpriteAnimation get guardAnimation => _guardAnimation;

  bool _isGuarding = false;
  bool get isGuarding => _isGuarding;

  @override
  FutureOr<Map<UnitState, SpriteAnimation>> loadAnimations() {
    final idle = loadUnitAnimation(
      filename: 'Warrior_Idle.png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );

    final run = loadUnitAnimation(
      filename: 'Warrior_Run.png',
      textureSize: _frameSize,
      stepTime: 0.12,
    );

    _attack1Animation = loadUnitAnimation(
      filename: 'Warrior_Attack1.png',
      textureSize: _frameSize,
      stepTime: 0.08,
      loop: false,
    );

    _attack2Animation = loadUnitAnimation(
      filename: 'Warrior_Attack2.png',
      textureSize: _frameSize,
      stepTime: 0.1,
      loop: false,
    );

    _guardAnimation = loadUnitAnimation(
      filename: 'Warrior_Guard.png',
      textureSize: _frameSize,
      stepTime: 0.2,
    );

    return {
      UnitState.idle: idle,
      UnitState.run: run,
      UnitState.attack1: _attack1Animation,
      UnitState.attack2: _attack2Animation,
      UnitState.guard: _guardAnimation,
    };
  }

  // Warrior-specific methods
  Future<void> performAttack({bool useCombo = false}) async {
    if (!canAttack()) return;

    final attackState = useCombo 
        ? (Random().nextBool() ? UnitState.attack1 : UnitState.attack2)
        : UnitState.attack1;
        
    await startAttack(attackState);
  }

  void startGuard() {
    if (isDead || isAttacking) return;
    
    _isGuarding = true;
    current = UnitState.guard;
  }

  void stopGuard() {
    if (!_isGuarding) return;
    
    _isGuarding = false;
    current = UnitState.idle;
  }

  @override
  void takeDamage(double damage) {
    // Reduce damage if guarding
    final actualDamage = _isGuarding ? damage * 0.3 : damage;
    super.takeDamage(actualDamage);
  }

  @override
  void updateBehavior(double dt) {
    super.updateBehavior(dt);
    
    // Add warrior-specific behavior here
    // For example: aggressive combat AI, charge attacks, etc.
  }
}