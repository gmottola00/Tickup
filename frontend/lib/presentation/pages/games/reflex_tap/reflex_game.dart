import 'package:flutter/material.dart';
import 'package:tickup/core/game_engine/game_interface.dart';
import 'package:tickup/core/game_engine/game_result.dart';
import 'package:tickup/presentation/features/logic_games/reflex_logic.dart';

/// Widget del gioco "Reflex Tap"
class ReflexGame extends StatefulWidget implements GameInterface {
  @override
  _ReflexGameState createState() => _ReflexGameState();

  @override
  Future<GameResult?> startGame(BuildContext context) {
    return Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => this),
    );
  }
}

class _ReflexGameState extends State<ReflexGame> {
  final logic = ReflexLogic(timeLeft: 10.0);
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    logic.start();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reflex Tap')),
      body: GestureDetector(
        onTapUp: (details) {
          logic.tap(details.localPosition, MediaQuery.of(context).size);
        },
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            if (logic.timeLeft <= 0) {
              final duration = DateTime.now().difference(_start);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Score: ${logic.score}',
                        style: TextStyle(fontSize: 32)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          GameResult(score: logic.score, duration: duration),
                        );
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
            // Mostra il bersaglio
            return Stack(
              children: [
                Positioned(
                  left: logic.targetPosition.dx *
                          MediaQuery.of(context).size.width -
                      25,
                  top: logic.targetPosition.dy *
                          MediaQuery.of(context).size.height -
                      25,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text('Time: ${logic.timeLeft.toStringAsFixed(1)}s'),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Text('Score: ${logic.score}'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
