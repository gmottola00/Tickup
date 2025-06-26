import 'package:flutter/material.dart';
import '../../../../core/input/input_mapper.dart';
import 'package:tickup/presentation/features/logic_games/space_invaders_logic.dart';
import 'package:go_router/go_router.dart';

class SpaceInvadersPage extends StatefulWidget {
  const SpaceInvadersPage({super.key});

  @override
  State<SpaceInvadersPage> createState() => _SpaceInvadersPageState();
}

class _SpaceInvadersPageState extends State<SpaceInvadersPage> {
  late final SpaceInvadersLogic logic;

  @override
  void initState() {
    super.initState();
    logic = SpaceInvadersLogic()..start();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          logic.setSize(Size(
            constraints.maxWidth,
            constraints.maxHeight,
          ));

          return InputMapper.wrap(
              logic,
              Stack(
                children: [
                  // CustomPaint
                  AnimatedBuilder(
                    animation: logic,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: _SpaceInvadersPainter(logic),
                    ),
                  ),

                  // HUD
                  Positioned(
                    top: 16,
                    left: 16,
                    child: AnimatedBuilder(
                      animation: logic,
                      builder: (_, __) => DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time: ${logic.timeLeft.toStringAsFixed(0)}'),
                            Text('Score: ${logic.score}'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 🔑 overlay dentro AnimatedBuilder
                  AnimatedBuilder(
                    animation: logic,
                    builder: (_, __) {
                      if (!logic.gameOver) return const SizedBox.shrink();
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GAME OVER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Score: ${logic.score}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: logic.restart,
                              child: const Text('Restart'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Home'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ));
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Painter
/// ---------------------------------------------------------------------------

class _SpaceInvadersPainter extends CustomPainter {
  _SpaceInvadersPainter(this.logic);
  final SpaceInvadersLogic logic;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Nave
    paint.color = Colors.white;
    const shipH = 20.0;
    const shipW = 28.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(logic.playerX, size.height - shipH * 2),
        width: shipW,
        height: shipH,
      ),
      paint,
    );

    // Proiettili
    paint.color = Colors.red;
    for (final b in logic.bullets) {
      canvas.drawRect(b.toRect(), paint);
    }

    // Alieni
    paint.color = Colors.greenAccent;
    for (final a in logic.aliens.where((e) => e.alive)) {
      canvas.drawRect(a.toRect(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpaceInvadersPainter oldDelegate) =>
      true; // ogni tick
}
