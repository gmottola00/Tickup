import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';
import 'package:tickup/pixel_adventure.dart';

enum TerrainSurfaceVariant { sand, mud, ice }

class TerrainSurfaceController extends PositionComponent
    with HasGameReference<PixelAdventure> {
  TerrainSurfaceController({
    required this.variant,
    Vector2? tileSize,
    this.emitParticles = true,
    super.position,
  }) : tileSize = tileSize ?? Vector2(16, 6);

  final TerrainSurfaceVariant variant;
  final Vector2 tileSize;
  final bool emitParticles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_buildSurface());
    if (emitParticles) {
      add(_buildParticleEmitter());
    }
  }

  SpriteComponent _buildSurface() {
    final image =
        game.images.fromCache('Traps/Sand Mud Ice/Sand Mud Ice (16x6).png');
    final index = switch (variant) {
      TerrainSurfaceVariant.sand => 0,
      TerrainSurfaceVariant.mud => 1,
      TerrainSurfaceVariant.ice => 2,
    };
    final rect = Rect.fromLTWH(
      index * tileSize.x,
      0,
      tileSize.x,
      tileSize.y,
    );
    final sprite = Sprite(
      image,
      srcSize: tileSize,
      srcPosition: Vector2(rect.left, rect.top),
    );
    return SpriteComponent(
      sprite: sprite,
      size: tileSize,
    );
  }

  SpriteAnimationComponent _buildParticleEmitter() {
    final (path, frameSize) = switch (variant) {
      TerrainSurfaceVariant.sand =>
        ('Traps/Sand Mud Ice/Sand Particle.png', Vector2(16, 6)),
      TerrainSurfaceVariant.mud =>
        ('Traps/Sand Mud Ice/Mud Particle.png', Vector2(16, 6)),
      TerrainSurfaceVariant.ice =>
        ('Traps/Sand Mud Ice/Ice Particle.png', Vector2(16, 6)),
    };

    final animation = loadSequencedAnimation(
      images: game.images,
      path: path,
      textureSize: frameSize,
      stepTime: 0.12,
    );

    return SpriteAnimationComponent(
      animation: animation,
      position: Vector2.zero(),
      size: frameSize,
      anchor: Anchor.bottomCenter,
      playing: true,
    );
  }
}
