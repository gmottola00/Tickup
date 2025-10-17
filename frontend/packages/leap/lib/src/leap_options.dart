import 'dart:ui';

import 'package:tiled/tiled.dart';

/// A configurable class that allows the developer to
/// customize different options that Leap will use
/// when reading the map.
class LeapConfiguration {
  const LeapConfiguration({
    this.tiled = const TiledOptions(),
  });

  /// The tiled options, change it to configure how Leap
  /// interpret the tiled map.
  final TiledOptions tiled;
}

/// A configurable class specifically about Tiled names, classes and etc.
class TiledOptions {
  const TiledOptions({
    this.groundLayerName = 'Ground',
    this.metadataLayerName = 'Metadata',
    this.playerSpawnClass = 'PlayerSpawn',
    this.hazardClass = 'Hazard',
    this.damageProperty = 'Damage',
    this.platformClass = 'Platform',
    this.slopeType = 'Slope',
    this.slopeRightTopProperty = 'RightTop',
    this.slopeLeftTopProperty = 'LeftTop',
    this.tagsProperty = 'Tags',
    this.atlasMaxX,
    this.atlasMaxY,
    this.tsxPackingFilter,
    this.layerPaintFactory,
    this.atlasPackingSpacingX = 0,
    this.atlasPackingSpacingY = 0,
  });

  /// Which layer name should be used for the player, defaults to "Ground".
  final String groundLayerName;

  /// Which layer name should be used for the metadata, defaults to "Metadata".
  final String metadataLayerName;

  /// Which class name should be used for the player spawn point,
  /// defaults to "PlayerSpawn".
  final String playerSpawnClass;

  /// Whick class name represents hazard objects, defaults to "Hazard".
  final String hazardClass;

  /// Which property name represents damage, defaults to "Damage".
  final String damageProperty;

  /// Which class name represents platform objects, defaults to "Platform".
  final String platformClass;

  /// Which property name represents the slope type, defaults to "Slope".
  final String slopeType;

  /// Which property name represents the slope left bottom, defaults to
  /// "RightTop".
  final String slopeRightTopProperty;

  /// Which property name represents the slope right bottom, defaults to
  /// "LeftTop".
  final String slopeLeftTopProperty;

  /// Property storing comma separated tags, defaults to "Tags".
  final String tagsProperty;

  /// Maximum width for generated tile atlases.
  final double? atlasMaxX;

  /// Maximum height for generated tile atlases.
  final double? atlasMaxY;

  /// Optional filter to exclude TSX files from atlas packing.
  final bool Function(Tileset)? tsxPackingFilter;

  /// Factory for customizing layer paint when rendering.
  final Paint Function(double opacity)? layerPaintFactory;

  /// Horizontal spacing used when packing atlases.
  final double atlasPackingSpacingX;

  /// Vertical spacing used when packing atlases.
  final double atlasPackingSpacingY;
}
