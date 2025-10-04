import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tickup/presentation/routing/app_route.dart';

class GameLauncher extends StatelessWidget {
  const GameLauncher({Key? key}) : super(key: key);

  static const List<Map<String, String>> _games = [
    {'title': 'Stop Bar', 'route': '/games/stop_bar'},
    {'title': 'Reflex Tap', 'route': '/games/reflex_tap'},
    {'title': 'Space Invaders', 'route': '/games/space_invaders'},
    {'title': 'Tanks (Unity)', 'route': AppRoute.unityTanks},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleziona un Gioco')),
      body: ListView.builder(
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return ListTile(
            title: Text(game['title']!),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => context.go(game['route']!),
          );
        },
      ),
    );
  }
}
