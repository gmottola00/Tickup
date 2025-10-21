import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/collision_block.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/pixel_adventure.dart';

class PlantProjectile extends SpriteComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  PlantProjectile({
    required super.position,
    required this.direction,
    this.speed = 220,
    this.maxTravelDistance = 640,
    super.size,
  }) : super(anchor: Anchor.center);

  final Vector2 direction;
  final double speed;
  final double maxTravelDistance;

  late final Vector2 _normalizedDir;
  late final Vector2 _startPosition;
  bool _impacted = false;
  double _impactTimer = 0;
  static const double _impactLifetime = 0.25;

  @override
  Future<void> onLoad() async {
    final spriteImage = game.images.fromCache('Enemies/Plant/Bullet.png');
    sprite ??= Sprite(spriteImage);
    size = size ??
        Vector2(
          spriteImage.width.toDouble(),
          spriteImage.height.toDouble(),
        );
    _normalizedDir = direction.normalized();
    _startPosition = position.clone();
    if (_normalizedDir.x < 0) {
      scale.x = -1;
    }

    add(CircleHitbox()..collisionType = CollisionType.active);
    priority = 5;

    await super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_impacted) {
      position += _normalizedDir * speed * dt;
      if (position.distanceTo(_startPosition) > maxTravelDistance) {
        removeFromParent();
      }
    } else {
      _impactTimer += dt;
      if (_impactTimer >= _impactLifetime) {
        removeFromParent();
      }
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (_impacted) return;
    if (other is Player) {
      other.collidedwithEnemy();
      _explode();
    } else if (other is CollisionBlock) {
      _explode();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _explode() {
    _impacted = true;
    final piecesImage =
        game.images.fromCache('Enemies/Plant/Bullet Pieces.png');
    sprite = Sprite(piecesImage);
    size = Vector2(
      piecesImage.width.toDouble(),
      piecesImage.height.toDouble(),
    );
    scale.x = 1;
  }
}
