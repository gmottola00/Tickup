import 'package:flutter/material.dart';
import '../games/stop_bar/stop_bar_game.dart';
import '../games/reflex_tap/reflex_game.dart';
import 'package:tickup/presentation/pages/games/space_invaders/space_invaders_game.dart';

class GameRunner extends StatelessWidget {
  final String gameId;
  const GameRunner({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildGameWidget(gameId);
  }

  Widget _buildGameWidget(String id) {
    switch (id) {
      case 'space_invaders':
        return const SpaceInvadersPage();
      case 'stop_bar':
        return const StopBarGame();
      case 'reflex_tap':
        return ReflexGame();
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Gioco non trovato')),
          body: Center(child: Text('ID gioco: $id non valido')),
        );
    }
  }
}
