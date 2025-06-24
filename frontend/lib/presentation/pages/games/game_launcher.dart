import 'package:flutter/material.dart';
import '../games/stop_bar/stop_bar_game.dart';
import '../games/reflex_tap/reflex_game.dart';

/// Lancia il gioco in base all'id passato (es: 'stop_bar', 'reflex_tap')
class GameLauncher extends StatelessWidget {
  final String gameId;
  const GameLauncher({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget gameWidget;
    switch (gameId) {
      case 'stop_bar':
        gameWidget = StopBarGame();
        break;
      case 'reflex_tap':
        gameWidget = ReflexGame();
        break;
      default:
        gameWidget = Scaffold(
          appBar: AppBar(title: Text('Gioco non trovato')),
          body: Center(child: Text('ID gioco: \$gameId non valido')),
        );
    }
    return gameWidget;
  }
}
