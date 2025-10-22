import 'package:tickup/components/shared/enemy_projectile.dart';

class TrunkProjectile extends EnemyProjectile {
  TrunkProjectile({
    required super.position,
    required super.direction,
    super.speed = 200,
    super.maxTravelDistance = 600,
    super.size,
  }) : super(
          enemyType: 'Trunk',
          impactLifetime: 0.3,
        );
}