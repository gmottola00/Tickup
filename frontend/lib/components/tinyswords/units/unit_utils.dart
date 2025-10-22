import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/archer_unit.dart';
import 'package:tickup/components/tinyswords/units/base_unit.dart';
import 'package:tickup/components/tinyswords/units/lancer_unit.dart';
import 'package:tickup/components/tinyswords/units/monk_unit.dart';
import 'package:tickup/components/tinyswords/units/unit_enums.dart';
import 'package:tickup/components/tinyswords/units/warrior_unit.dart';

class UnitFactory {
  static BaseUnit createUnit({
    required UnitType type,
    required UnitColor color,
    Vector2? position,
    Vector2? size,
  }) {
    switch (type) {
      case UnitType.warrior:
        return Warrior(
          position: position,
          size: size,
          unitColor: color,
        );
      case UnitType.archer:
        return Archer(
          position: position,
          size: size,
          unitColor: color,
        );
      case UnitType.monk:
        return Monk(
          position: position,
          size: size,
          unitColor: color,
        );
      case UnitType.lancer:
        return Lancer(
          position: position,
          size: size,
          unitColor: color,
        );
    }
  }

  static List<BaseUnit> createArmy({
    required List<UnitType> unitTypes,
    required UnitColor color,
    required Vector2 startPosition,
    Vector2? formation,
  }) {
    final army = <BaseUnit>[];
    formation ??= Vector2(50, 50); // Default formation spacing
    
    for (int i = 0; i < unitTypes.length; i++) {
      final row = i ~/ 5; // 5 units per row
      final col = i % 5;
      
      final unitPosition = Vector2(
        startPosition.x + col * formation.x,
        startPosition.y + row * formation.y,
      );
      
      final unit = createUnit(
        type: unitTypes[i],
        color: color,
        position: unitPosition,
      );
      
      army.add(unit);
    }
    
    return army;
  }
}

class BattleManager {
  static List<BaseUnit> _allUnits = [];
  
  static void registerUnit(BaseUnit unit) {
    _allUnits.add(unit);
  }
  
  static void unregisterUnit(BaseUnit unit) {
    _allUnits.remove(unit);
  }
  
  static List<BaseUnit> getUnitsInRadius(Vector2 center, double radius) {
    return _allUnits
        .where((unit) => !unit.isDead && 
                        center.distanceTo(unit.position) <= radius)
        .toList();
  }
  
  static List<BaseUnit> getEnemyUnitsInRange(
    BaseUnit attacker, 
    double range,
  ) {
    return _allUnits
        .where((unit) => 
            !unit.isDead && 
            unit.unitColor != attacker.unitColor &&
            attacker.position.distanceTo(unit.position) <= range)
        .toList();
  }
  
  static List<BaseUnit> getAllyUnitsInRange(
    BaseUnit unit, 
    double range,
  ) {
    return _allUnits
        .where((ally) => 
            !ally.isDead && 
            ally != unit &&
            ally.unitColor == unit.unitColor &&
            unit.position.distanceTo(ally.position) <= range)
        .toList();
  }
  
  static BaseUnit? findNearestEnemy(BaseUnit unit) {
    BaseUnit? nearestEnemy;
    double nearestDistance = double.infinity;
    
    for (final enemy in _allUnits) {
      if (enemy.isDead || enemy.unitColor == unit.unitColor) continue;
      
      final distance = unit.position.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestEnemy = enemy;
      }
    }
    
    return nearestEnemy;
  }
  
  static void clear() {
    _allUnits.clear();
  }
}

extension UnitExtensions on BaseUnit {
  bool isEnemy(BaseUnit other) {
    return unitColor != other.unitColor;
  }
  
  bool isAlly(BaseUnit other) {
    return unitColor == other.unitColor && this != other;
  }
  
  double distanceTo(BaseUnit other) {
    return position.distanceTo(other.position);
  }
  
  Vector2 directionTo(BaseUnit other) {
    return (other.position - position).normalized();
  }
  
  bool isInAttackRange(BaseUnit target) {
    return distanceTo(target) <= attackRange;
  }
  
  Vector2 calculateMovementVector(Vector2 target) {
    final direction = (target - position).normalized();
    return direction * moveSpeed;
  }
}