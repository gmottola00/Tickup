import 'dart:async';

import 'package:flame/components.dart';
import 'package:tickup/components/traps/trap_sprite_utils.dart';
import 'package:tickup/pixel_adventure.dart';

enum ArrowTrapState { idle, hit }

class ArrowTrap extends SpriteAnimationGroupComponent<ArrowTrapState>
    with HasGameReference<PixelAdventure> {
  ArrowTrap({
    super.position,
    super.size,
  });

  static final _frameSize = Vector2(18, 18);

  @override
  Future<void> onLoad() async {
    animations = await _loadAnimations();
    current = ArrowTrapState.idle;
    await super.onLoad();
  }

  Future<Map<ArrowTrapState, SpriteAnimation>> _loadAnimations() async {
    return {
      ArrowTrapState.idle: loadSequencedAnimation(
        images: game.images,
        path: 'Traps/Arrow/Idle (18x18).png',
        textureSize: _frameSize,
        stepTime: 0.1,
      ),
      ArrowTrapState.hit: loadSequencedAnimation(
        images: game.images,
        path: 'Traps/Arrow/Hit (18x18).png',
        textureSize: _frameSize,
        stepTime: 0.08,
        loop: false,
      ),
    };
  }

  Future<void> trigger() async {
    if (current == ArrowTrapState.hit) return;
    current = ArrowTrapState.hit;
    await animationTicker?.completed;
    current = ArrowTrapState.idle;
  }
}
