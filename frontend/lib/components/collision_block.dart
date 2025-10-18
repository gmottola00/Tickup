import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
  });

  final bool isPlatform;
}
