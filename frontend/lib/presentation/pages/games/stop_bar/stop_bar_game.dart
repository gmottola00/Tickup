import 'package:flutter/material.dart';
import 'package:tickup/core/game_engine/game_interface.dart';
import 'package:tickup/core/game_engine/game_result.dart';
import 'package:tickup/presentation/state/games/stop_bar_logic.dart';

/// Widget del gioco "Ferma la barra" che implementa GameInterface
class StopBarGame extends StatefulWidget implements GameInterface {
  @override
  _StopBarGameState createState() => _StopBarGameState();

  @override
  Future<GameResult?> startGame(BuildContext context) {
    return Navigator.of(context).push<GameResult>(
      MaterialPageRoute(builder: (_) => this),
    );
  }
}

class _StopBarGameState extends State<StopBarGame> {
  final logic = StopBarLogic();
  GameResult? result;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(title: Text('Ferma la barra')),
      body: Center(
        child: AnimatedBuilder(
          animation: logic,
          builder: (context, _) {
            if (logic.gameOver) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    logic.score > 0 ? '✅ Success! +10 punti' : '❌ Missed!',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      logic.restart();
                    },
                    child: Text('Ricomincia'),
                  ),
                ],
              );
            }
            // Barra e zona verde
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(height: 50, width: 300, color: Colors.grey[300]),
                    Positioned(
                      left: 300 * logic.greenStart,
                      child: Container(
                        height: 50,
                        width: 300 * (logic.greenEnd - logic.greenStart),
                        color: Colors.green,
                      ),
                    ),
                    Positioned(
                      left: 300 * logic.position,
                      child:
                          Container(height: 50, width: 10, color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => logic.stop((res) {
                    Navigator.of(context).pop(res);
                  }),
                  child: Text('STOP!'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
