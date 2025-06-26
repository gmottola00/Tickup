import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameLauncher extends StatelessWidget {
  const GameLauncher({Key? key}) : super(key: key);

  static const List<Map<String, String>> _games = [
    {'id': 'stop_bar', 'name': 'Stop Bar'},
    {'id': 'reflex_tap', 'name': 'Reflex Tap'},
    {'id': 'space_invaders', 'name': 'Space Invaders'},
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
            title: Text(game['name']!),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => context.go('/games/${game['id']}'),
          );
        },
      ),
    );
  }
}
