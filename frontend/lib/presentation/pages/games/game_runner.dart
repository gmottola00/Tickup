import 'package:flutter/material.dart';
import 'package:tickup/presentation/pages/games/pixel_adventure_menu.dart';

class GameRunner extends StatelessWidget {
  final String gameId;
  const GameRunner({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildGameWidget(gameId);
  }

  Widget _buildGameWidget(String id) {
    switch (id) {
      case 'pixel_adventure':
        return const PixelAdventureMenuPage();
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
