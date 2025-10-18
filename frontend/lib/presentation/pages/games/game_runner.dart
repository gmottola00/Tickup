import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tickup/pixel_adventure.dart';

class GameRunner extends StatefulWidget {
  final String gameId;
  const GameRunner({Key? key, required this.gameId}) : super(key: key);

  @override
  State<GameRunner> createState() => _GameRunnerState();
}

class _GameRunnerState extends State<GameRunner> {
  late final Widget _gameContent;

  @override
  void initState() {
    super.initState();
    _gameContent = _buildGameWidget(widget.gameId);
    _enterGameMode();
  }

  @override
  void dispose() {
    _exitGameMode();
    super.dispose();
  }

  void _enterGameMode() {
    unawaited(Flame.device.fullScreen());
    unawaited(Flame.device.setLandscape());
  }

  void _exitGameMode() {
    unawaited(Flame.device.restoreFullscreen());
    unawaited(Flame.device.setPortrait());
  }

  @override
  Widget build(BuildContext context) => _gameContent;

  Widget _buildGameWidget(String id) {
    switch (id) {
      case 'pixel_adventure':
        return Scaffold(
          backgroundColor: const Color(0xFF211F30),
          body: GameWidget(game: PixelAdventure()),
        );
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
