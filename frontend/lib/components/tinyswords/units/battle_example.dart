import 'package:flame/components.dart';
import 'package:tickup/components/tinyswords/units/tinyswords_units.dart';

/// Example usage of TinySwords Units
/// 
/// This demonstrates how to create and manage different unit types
/// with their various abilities and behaviors.
class TinySwordsBattleExample extends Component {
  late List<BaseUnit> blueArmy;
  late List<BaseUnit> redArmy;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create Blue Army
    blueArmy = UnitFactory.createArmy(
      unitTypes: [
        UnitType.warrior, UnitType.warrior, UnitType.warrior,
        UnitType.archer, UnitType.archer,
        UnitType.monk,
        UnitType.lancer, UnitType.lancer,
      ],
      color: UnitColor.blue,
      startPosition: Vector2(100, 300),
      formation: Vector2(80, 80),
    );
    
    // Create Red Army
    redArmy = UnitFactory.createArmy(
      unitTypes: [
        UnitType.lancer, UnitType.lancer, UnitType.lancer,
        UnitType.warrior, UnitType.warrior,
        UnitType.archer, UnitType.archer,
        UnitType.monk,
      ],
      color: UnitColor.red,
      startPosition: Vector2(600, 300),
      formation: Vector2(80, 80),
    );
    
    // Add all units to the game
    for (final unit in [...blueArmy, ...redArmy]) {
      add(unit);
      BattleManager.registerUnit(unit);
    }
    
    // Start battle simulation
    _startBattleSimulation();
  }
  
  void _startBattleSimulation() {
    // Example battle AI - very basic
    
    // Blue team behavior
    for (final unit in blueArmy) {
      _assignUnitBehavior(unit);
    }
    
    // Red team behavior  
    for (final unit in redArmy) {
      _assignUnitBehavior(unit);
    }
  }
  
  void _assignUnitBehavior(BaseUnit unit) {
    switch (unit.unitType) {
      case UnitType.warrior:
        _assignWarriorBehavior(unit as Warrior);
        break;
      case UnitType.archer:
        _assignArcherBehavior(unit as Archer);
        break;
      case UnitType.monk:
        _assignMonkBehavior(unit as Monk);
        break;
      case UnitType.lancer:
        _assignLancerBehavior(unit as Lancer);
        break;
    }
  }
  
  void _assignWarriorBehavior(Warrior warrior) {
    // Warriors: Aggressive front-line fighters
    // Find nearest enemy and charge
    final nearestEnemy = BattleManager.findNearestEnemy(warrior);
    if (nearestEnemy != null) {
      if (warrior.isInAttackRange(nearestEnemy)) {
        // In range - attack!
        warrior.performAttack(useCombo: true);
      } else {
        // Move towards enemy
        final movementVector = warrior.calculateMovementVector(nearestEnemy.position);
        // Apply movement logic here
      }
    }
  }
  
  void _assignArcherBehavior(Archer archer) {
    // Archers: Ranged support, keep distance
    final nearestEnemy = BattleManager.findNearestEnemy(archer);
    if (nearestEnemy != null) {
      if (archer.isInAttackRange(nearestEnemy)) {
        // In range - shoot!
        archer.shootAt(nearestEnemy.position);
      } else {
        // Move to get in range
        final movementVector = archer.calculateMovementVector(nearestEnemy.position);
        // Apply movement logic here
      }
    }
  }
  
  void _assignMonkBehavior(Monk monk) {
    // Monks: Healing support
    final healableAllies = monk.getHealableUnits();
    
    if (healableAllies.isNotEmpty) {
      // Find most wounded ally
      healableAllies.sort((a, b) => 
          a.healthPercentage.compareTo(b.healthPercentage));
      
      final mostWounded = healableAllies.first;
      if (mostWounded.healthPercentage < 0.5) {
        // Heal most wounded ally
        monk.healUnit(mostWounded);
      }
    }
    
    // If no healing needed, move to safer position
    final enemies = BattleManager.getEnemyUnitsInRange(monk, 150);
    if (enemies.isNotEmpty) {
      // Move away from danger
      final allies = BattleManager.getAllyUnitsInRange(monk, 100);
      if (allies.isNotEmpty) {
        // Move towards allies for protection
        final centerAlly = allies.first;
        final movementVector = monk.calculateMovementVector(centerAlly.position);
        // Apply movement logic here
      }
    }
  }
  
  void _assignLancerBehavior(Lancer lancer) {
    // Lancers: Tactical fighters with directional attacks
    final nearestEnemy = BattleManager.findNearestEnemy(lancer);
    if (nearestEnemy != null) {
      if (lancer.isInAttackRange(nearestEnemy)) {
        // In range - thrust attack!
        lancer.thrustAt(nearestEnemy.position);
      } else {
        // Move towards enemy
        final movementVector = lancer.calculateMovementVector(nearestEnemy.position);
        // Apply movement logic here
      }
      
      // Use defensive stance when overwhelmed
      final nearbyEnemies = BattleManager.getEnemyUnitsInRange(lancer, 100);
      if (nearbyEnemies.length >= 2) {
        // Multiple enemies - defend
        lancer.startDefence(nearestEnemy.position);
      }
    }
  }
}

/// Usage instructions:
/// 
/// To use TinySwords units in your game:
/// 
/// 1. Import the barrel file:
///    ```dart
///    import 'package:tickup/components/tinyswords/tinyswords_units.dart';
///    ```
/// 
/// 2. Create individual units:
///    ```dart
///    final warrior = Warrior(
///      position: Vector2(100, 100),
///      unitColor: UnitColor.blue,
///    );
///    ```
/// 
/// 3. Or create armies:
///    ```dart
///    final army = UnitFactory.createArmy(
///      unitTypes: [UnitType.warrior, UnitType.archer, UnitType.monk],
///      color: UnitColor.red,
///      startPosition: Vector2(200, 200),
///    );
///    ```
/// 
/// 4. Register units with battle manager:
///    ```dart
///    for (final unit in army) {
///      add(unit);
///      BattleManager.registerUnit(unit);
///    }
///    ```
/// 
/// 5. Use unit abilities:
///    ```dart
///    // Warrior abilities
///    warrior.performAttack();
///    warrior.startGuard();
///    
///    // Archer abilities
///    archer.shootAt(targetPosition);
///    archer.upgradeMultiShot(3);
///    
///    // Monk abilities
///    monk.healUnit(targetUnit);
///    monk.healArea(100);
///    
///    // Lancer abilities
///    lancer.thrustAt(targetPosition);
///    lancer.chargeAttack(targetPosition);
///    lancer.startDefence(threatDirection);
///    ```