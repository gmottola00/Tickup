import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tickup/components/background_tile.dart';
import 'package:tickup/components/checkpoint.dart';
import 'package:tickup/components/chicken.dart';
import 'package:tickup/components/collision_block.dart';
import 'package:tickup/components/fruit.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/components/saw.dart';
import 'package:tickup/pixel_adventure.dart';

class Level extends World with HasGameReference<PixelAdventure> {
  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;
  final List<CollisionBlock> _collisionBlocks = [];

  @override
  Future<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));

    add(level);

    _scrollingBackground();
    _spawningObjects();
    _addCollisions();

    await super.onLoad();
  }

  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');

    if (backgroundLayer != null) {
      final backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor');
      final backgroundTile = BackgroundTile(
        color: backgroundColor ?? 'Gray',
        position: Vector2(0, 0),
      );
      add(backgroundTile);
    }
  }

  void _spawningObjects() {
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if (spawnPointsLayer == null) {
      return;
    }

    for (final spawnPoint in spawnPointsLayer.objects) {
      final position = Vector2(spawnPoint.x, spawnPoint.y);
      final size = Vector2(spawnPoint.width, spawnPoint.height);

      switch (spawnPoint.class_) {
        case 'Player':
          player
            ..position = position
            ..scale.x = 1;
          add(player);
          break;
        case 'Fruit':
          add(
            Fruit(
              fruit: spawnPoint.name,
              position: position,
              size: size,
            ),
          );
          break;
        case 'Saw':
          add(
            Saw(
              isVertical: spawnPoint.properties.getValue('isVertical'),
              offNeg: spawnPoint.properties.getValue('offNeg'),
              offPos: spawnPoint.properties.getValue('offPos'),
              position: position,
              size: size,
            ),
          );
          break;
        case 'Checkpoint':
          add(
            Checkpoint(
              position: position,
              size: size,
            ),
          );
          break;
        case 'Chicken':
          add(
            Chicken(
              position: position,
              size: size,
              offNeg: spawnPoint.properties.getValue('offNeg'),
              offPos: spawnPoint.properties.getValue('offPos'),
            ),
          );
          break;
        default:
      }
    }
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if (collisionsLayer == null) {
      return;
    }

    for (final collision in collisionsLayer.objects) {
      final block = CollisionBlock(
        position: Vector2(collision.x, collision.y),
        size: Vector2(collision.width, collision.height),
        isPlatform: collision.class_ == 'Platform',
      );
      _collisionBlocks.add(block);
      add(block);
    }
    player.collisionBlocks = _collisionBlocks;
  }
}
