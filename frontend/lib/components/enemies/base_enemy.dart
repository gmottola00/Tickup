import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:meta/meta.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/pixel_adventure.dart';

enum EnemyState { idle, run, attack, hit }

abstract class BaseEnemy extends SpriteAnimationGroupComponent<EnemyState>
    with HasGameReference<PixelAdventure>, CollisionCallbacks {
  BaseEnemy({
    super.position,
    super.size,
    this.offNeg = 0,
    this.offPos = 0,
    this.tileSize = 16,
    Vector2? hitboxSize,
    Vector2? hitboxOffset,
    this.runSpeed = 80,
    this.bounceHeight = 260,
    this.grantScore = true,
    this.stompSound = 'bounce.wav',
  })  : hitboxSize = hitboxSize ?? Vector2.all(16),
        hitboxOffset = hitboxOffset ?? Vector2.zero();

  final double offNeg;
  final double offPos;
  final double tileSize;
  final Vector2 hitboxSize;
  final Vector2 hitboxOffset;
  final double runSpeed;
  final double bounceHeight;
  final bool grantScore;
  final String? stompSound;

  @protected
  final Vector2 velocity = Vector2.zero();
  @protected
  late final Player player;

  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 1;
  double targetDirection = -1;
  bool gotStomped = false;

  @override
  Future<void> onLoad() async {
    player = game.player;
    add(
      RectangleHitbox(
        position: hitboxOffset,
        size: hitboxSize,
      ),
    );
    animations = await loadAnimations();
    current = EnemyState.idle;
    if (size.x == 0 && size.y == 0) {
      final frameSize = animations?[EnemyState.idle]?.frames.first.sprite.srcSize;
      if (frameSize != null) {
        size
          ..x = frameSize.x
          ..y = frameSize.y;
      }
    }
    _calculateRange();
    await super.onLoad();
  }

  FutureOr<Map<EnemyState, SpriteAnimation>> loadAnimations();

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      updateState();
      movement(dt);
    }
    super.update(dt);
  }

  @protected
  void movement(double dt) {
    velocity.x = 0;
    final double playerOffset = player.scale.x > 0 ? 0.0 : -player.width;
    final double enemyOffset = scale.x > 0 ? 0.0 : -width;

    if (playerInRange(playerOffset)) {
      targetDirection =
          (player.x + playerOffset < position.x + enemyOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
    position.x += velocity.x * dt;
  }

  bool playerInRange(double playerOffset) {
    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  @protected
  void updateState() {
    current = velocity.x != 0 ? EnemyState.run : EnemyState.idle;

    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  Future<void> collidedWithPlayer() async {
    if (gotStomped) return;
    final playerBottom = player.y + player.height;
    if (player.velocity.y > 0 && playerBottom > position.y) {
      await onStomped();
    } else {
      onPlayerHit();
    }
  }

  @mustCallSuper
  Future<void> onStomped() async {
    if (stompSound != null && game.playSounds) {
      FlameAudio.play(stompSound!, volume: game.soundVolume);
    }
    if (grantScore) {
      game.addScore(game.enemyScoreValue);
    }
    gotStomped = true;
    current = EnemyState.hit;
    player.velocity.y = -bounceHeight;
    await animationTicker?.completed;
    removeFromParent();
  }

  @protected
  void onPlayerHit() {
    player.collidedwithEnemy();
  }
}
