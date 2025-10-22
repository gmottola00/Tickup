import 'package:tickup/components/shared/enemy_projectile.dart';

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
