import 'package:flutter/material.dart';
import 'package:tickup/presentation/features/super_dash/super_dash_game_screen.dart';

class GameRunner extends StatelessWidget {
  final String gameId;
  const GameRunner({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildGameWidget(gameId);
  }

  Widget _buildGameWidget(String id) {
    switch (id) {
      case 'super_dash':
        return const SuperDashGameScreen();
      // case 'space_invaders':
      //   return const SpaceInvadersPage();
      // case 'stop_bar':
      //   return const StopBarGame();
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Gioco non trovato')),
          body: Center(child: Text('ID gioco: $id non valido')),
        );
    }
  }
}
