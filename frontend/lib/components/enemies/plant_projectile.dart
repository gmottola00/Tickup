import 'package:tickup/components/enemies/enemy_projectile.dart';

class PlantProjectile extends EnemyProjectile {
  PlantProjectile({
    required super.position,
    required super.direction,
    super.speed = 240,
    super.maxTravelDistance = 640,
    super.size,
  }) : super(
          enemyType: 'Plant',
          impactLifetime: 0.25,
        );
}
