import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tickup/components/collision_block.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/pixel_adventure.dart';

class EnemyProjectile extends SpriteComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  EnemyProjectile({
    required super.position,
    required this.direction,
    required this.enemyType,
    this.speed = 220,
    this.maxTravelDistance = 640,
    this.impactLifetime = 0.25,
    super.size,
  }) : super(anchor: Anchor.center);

  final Vector2 direction;
  final String enemyType; // 'Plant', 'Trunk', etc.
  final double speed;
  final double maxTravelDistance;
  final double impactLifetime;

  late final Vector2 _normalizedDir;
  late final Vector2 _startPosition;
  bool _impacted = false;
  double _impactTimer = 0;

  String get _bulletSpritePath => 'Enemies/$enemyType/Bullet.png';
  String get _bulletPiecesSpritePath => 'Enemies/$enemyType/Bullet Pieces.png';

  @override
  Future<void> onLoad() async {
    final spriteImage = game.images.fromCache(_bulletSpritePath);
    sprite ??= Sprite(spriteImage);
    if (size == Vector2.zero()) {
      size = Vector2(
        spriteImage.width.toDouble(),
        spriteImage.height.toDouble(),
      );
    }
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
      if (_impactTimer >= impactLifetime) {
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
    final piecesImage = game.images.fromCache(_bulletPiecesSpritePath);
    sprite = Sprite(piecesImage);
    size = Vector2(
      piecesImage.width.toDouble(),
      piecesImage.height.toDouble(),
    );
    scale.x = 1;
  }
}