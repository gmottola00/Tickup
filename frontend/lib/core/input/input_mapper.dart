import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tickup/presentation/features/logic_games/space_invaders_logic.dart';

/// Mappa input tastiera (desktop/web) e gesture touch (mobile)
/// sui comandi di [SpaceInvadersLogic].
class InputMapper extends StatelessWidget {
  const InputMapper({
    super.key,
    required this.logic,
    required this.child,
  });

  final SpaceInvadersLogic logic;
  final Widget child;

  /// Helper rapido:
  /// ```dart
  /// body: InputMapper.wrap(logic, child)
  /// ```
  static Widget wrap(SpaceInvadersLogic logic, Widget child) =>
      InputMapper(logic: logic, child: child);

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        // gestiamo solo il "key down"
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.keyA) {
            logic.moveLeft();
          }
          if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.keyD) {
            logic.moveRight();
          }
          if (key == LogicalKeyboardKey.space) {
            logic.fire();
          }
        }
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < 0) {
            logic.moveLeft();
          } else {
            logic.moveRight();
          }
        },
        onTap: () => logic.fire(), // firma corretta
        child: child,
      ),
    );
  }
}
