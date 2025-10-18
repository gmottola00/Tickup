import 'package:flame/cache.dart';
import 'package:flame/components.dart';

SpriteAnimation loadSequencedAnimation({
  required Images images,
  required String path,
  required Vector2 textureSize,
  required double stepTime,
  bool loop = true,
}) {
  final image = images.fromCache(path);
  final frameCount = (image.width / textureSize.x).round();
  return SpriteAnimation.fromFrameData(
    image,
    SpriteAnimationData.sequenced(
      amount: frameCount,
      stepTime: stepTime,
      textureSize: textureSize,
      loop: loop,
    ),
  );
}
