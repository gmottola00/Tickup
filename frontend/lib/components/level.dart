import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tickup/components/background_tile.dart';
import 'package:tickup/components/checkpoint.dart';
import 'package:tickup/components/collision_block.dart';
import 'package:tickup/components/fruit.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/components/traps/traps.dart';
import 'package:tickup/components/enemies/enemies.dart';
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
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'AngryPig':
          add(
            AngryPig(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Bat':
          add(
            Bat(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Bee':
          add(
            Bee(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'BlueBird':
          add(
            BlueBird(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Bunny':
          add(
            Bunny(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Chameleon':
          add(
            Chameleon(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Duck':
          add(
            Duck(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'FatBird':
          add(
            FatBird(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Ghost':
          add(
            Ghost(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Mushroom':
          add(
            Mushroom(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Plant':
          add(
            Plant(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Radish':
          add(
            Radish(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Rino':
          add(
            Rino(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Rocks':
          add(
            RockEnemy(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
              variant: _parseRockVariant(spawnPoint),
            ),
          );
          break;
        case 'Skull':
          add(
            Skull(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Slime':
          add(
            Slime(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Snail':
          add(
            Snail(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Trunk':
          add(
            Trunk(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Turtle':
          add(
            Turtle(
              position: position,
              size: size,
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Saw':
          add(
            SawTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'SpikedBall':
          add(
            SpikedBallTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'MovingPlatform':
          add(
            MovingPlatformTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
              skin: _parsePlatformSkin(spawnPoint),
            ),
          );
          break;
        case 'Fan':
          add(
            FanTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Fire':
          add(
            FireTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Arrow':
          add(
            ArrowTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'RockHead':
          add(
            RockHeadTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'SpikeHead':
          add(
            SpikeHeadTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Spikes':
          add(
            SpikesTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Trampoline':
          add(
            TrampolineTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'FallingPlatforms':
        case 'FallingPlatform':
          add(
            FallingPlatformTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'Blocks':
          add(
            BlockTrap(
              position: position,
              size: size,
              isVertical: _boolProp(spawnPoint, 'isVertical'),
              offNeg: _doubleProp(spawnPoint, 'offNeg'),
              offPos: _doubleProp(spawnPoint, 'offPos'),
            ),
          );
          break;
        case 'TerrainSurface':
        case 'SandMudIce':
          add(
            TerrainSurfaceController(
              position: position,
              variant: _parseTerrainVariant(spawnPoint),
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

  bool _boolProp(TiledObject object, String name, [bool defaultValue = false]) {
    final value = object.properties.getValue(name);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  double _doubleProp(TiledObject object, String name,
      [double defaultValue = 0]) {
    final value = object.properties.getValue(name);
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String? _stringProp(TiledObject object, String name) {
    final value = object.properties.getValue(name);
    return value?.toString();
  }

  MovingPlatformSkin _parsePlatformSkin(TiledObject object) {
    final value = _stringProp(object, 'skin');
    if (value == null) return MovingPlatformSkin.grey;
    switch (value.toLowerCase()) {
      case 'brown':
        return MovingPlatformSkin.brown;
      default:
        return MovingPlatformSkin.grey;
    }
  }

  TerrainSurfaceVariant _parseTerrainVariant(TiledObject object) {
    final value = _stringProp(object, 'variant');
    switch (value?.toLowerCase()) {
      case 'mud':
        return TerrainSurfaceVariant.mud;
      case 'ice':
        return TerrainSurfaceVariant.ice;
      default:
        return TerrainSurfaceVariant.sand;
    }
  }

  RockEnemyVariant _parseRockVariant(TiledObject object) {
    final value = _stringProp(object, 'variant');
    switch (value?.toLowerCase()) {
      case 'rock2':
        return RockEnemyVariant.rock2;
      case 'rock3':
        return RockEnemyVariant.rock3;
      default:
        return RockEnemyVariant.rock1;
    }
  }
}
