import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/units/base_unit.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';
import 'package:tickup/pixel_adventure.dart';

class HealEffect extends SpriteAnimationComponent with HasGameReference<PixelAdventure> {
  HealEffect({
    required super.position,
    required this.healAmount,
  }) : super(anchor: Anchor.center);

  final double healAmount;
  
  @override
  Future<void> onLoad() async {
    // Load heal effect animation
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('TinySwords/Units/Blue Units/Monk/Heal_Effect.png'),
      SpriteAnimationData.sequenced(
        amount: 8, // Assuming 8 frames, adjust as needed
        textureSize: Vector2(32, 32),
        stepTime: 0.1,
        loop: false,
      ),
    );
    
    size = Vector2(32, 32);
    await super.onLoad();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Remove when animation is complete
    if (animationTicker?.completed == true || animationTicker?.isLastFrame == true) {
      removeFromParent();
    }
  }
}

class Monk extends BaseUnit {
  Monk({
    super.position,
    super.size,
    super.unitColor = UnitColor.blue,
    super.maxHealth = 100,
    super.attackDamage = 0, // Monks don't attack directly
    super.moveSpeed = 85,
    super.attackRange = 80, // Heal range
  }) : super(
          unitType: UnitType.monk,
          hitboxOffset: Vector2(4, 8),
          hitboxSize: Vector2(24, 24),
        );

  static const double _stepTime = 0.15;
  static final Vector2 _frameSize = Vector2(32, 32);

  late final SpriteAnimation _healAnimation;
  SpriteAnimation get healAnimation => _healAnimation;

  double _healAmount = 30;
  double _healCooldown = 2.0;
  double _lastHealTime = 0;

  @override
  FutureOr<Map<UnitState, SpriteAnimation>> loadAnimations() {
    final idle = loadUnitAnimation(
      filename: 'Idle.png',
      textureSize: _frameSize,
      stepTime: _stepTime,
    );

    final run = loadUnitAnimation(
      filename: 'Run.png',
      textureSize: _frameSize,
      stepTime: 0.12,
    );

    _healAnimation = loadUnitAnimation(
      filename: 'Heal.png',
      textureSize: _frameSize,
      stepTime: 0.12,
      loop: false,
    );

    return {
      UnitState.idle: idle,
      UnitState.run: run,
      UnitState.heal: _healAnimation,
    };
  }

  // Monk-specific methods
  bool canHeal() {
    return !isDead && !isAttacking && _lastHealTime >= _healCooldown;
  }

  Future<void> healUnit(BaseUnit target) async {
    if (!canHeal() || target.isDead) return;
    
    final distanceToTarget = position.distanceTo(target.position);
    if (distanceToTarget > attackRange) return;

    _lastHealTime = 0;
    current = UnitState.heal;
    
    // Wait for animation to reach heal point (around 60% of animation)
    final healDelay = (_healAnimation.frames.length * 0.6 * 0.12);
    await Future.delayed(Duration(milliseconds: (healDelay * 1000).round()));
    
    // Perform heal
    target.heal(_healAmount);
    
    // Spawn heal effect
    final healEffect = HealEffect(
      position: target.position.clone(),
      healAmount: _healAmount,
    );
    parent?.add(healEffect);
    
    // Wait for animation to complete
    await animationTicker?.completed;
    current = UnitState.idle;
  }

  Future<void> healSelf() async {
    if (!canHeal()) return;
    
    await healUnit(this);
  }

  Future<void> healArea(double radius) async {
    if (!canHeal()) return;
    
    // Find all units in healing radius
    final unitsInRange = <BaseUnit>[];
    parent?.children.whereType<BaseUnit>().forEach((unit) {
      if (unit != this && 
          !unit.isDead && 
          position.distanceTo(unit.position) <= radius) {
        unitsInRange.add(unit);
      }
    });
    
    if (unitsInRange.isEmpty) return;
    
    _lastHealTime = 0;
    current = UnitState.heal;
    
    // Wait for animation heal point
    final healDelay = (_healAnimation.frames.length * 0.6 * 0.12);
    await Future.delayed(Duration(milliseconds: (healDelay * 1000).round()));
    
    // Heal all units in range
    for (final unit in unitsInRange) {
      unit.heal(_healAmount * 0.7); // Reduced healing for area effect
      
      final healEffect = HealEffect(
        position: unit.position.clone(),
        healAmount: _healAmount * 0.7,
      );
      parent?.add(healEffect);
    }
    
    // Wait for animation to complete
    await animationTicker?.completed;
    current = UnitState.idle;
  }

  // Monk upgrades/abilities
  void upgradeHealAmount(double amount) {
    _healAmount = amount;
  }

  void upgradeHealCooldown(double cooldown) {
    _healCooldown = cooldown;
  }

  List<BaseUnit> getHealableUnits() {
    final healableUnits = <BaseUnit>[];
    parent?.children.whereType<BaseUnit>().forEach((unit) {
      if (unit != this && 
          !unit.isDead && 
          unit.currentHealth < unit.maxHealth &&
          position.distanceTo(unit.position) <= attackRange) {
        healableUnits.add(unit);
      }
    });
    return healableUnits;
  }

  @override
  void updateBehavior(double dt) {
    super.updateBehavior(dt);
    _lastHealTime += dt;
    
    // Add monk-specific behavior here
    // For example: auto-healing low health allies
  }
}