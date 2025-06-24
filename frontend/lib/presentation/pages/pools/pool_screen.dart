import 'package:flutter/material.dart';
import '../games/stop_bar/stop_bar_game.dart';
import '../games/reflex_tap/reflex_game.dart';

/// Schermata che mostra i giochi disponibili
class PoolScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SkillWin Pools')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Ferma la barra'),
            onTap: () async {
              final result = await StopBarGame().startGame(context);
              // gestisci result (supabase, classifica...)
            },
          ),
          ListTile(
            title: Text('Reflex Tap'),
            onTap: () async {
              final result = await ReflexGame().startGame(context);
              // gestisci result
            },
          ),
        ],
      ),
    );
  }
}
