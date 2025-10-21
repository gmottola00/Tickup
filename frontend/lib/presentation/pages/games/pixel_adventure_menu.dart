import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/pixel_adventure.dart';
import 'package:tickup/components/player.dart';
import 'package:tickup/presentation/features/profile/avatar_catalog.dart';
import 'package:tickup/presentation/features/profile/profile_provider.dart';

class PixelAdventureMenuPage extends StatelessWidget {
  const PixelAdventureMenuPage({super.key});

  List<String> get _levels => PixelAdventure.defaultLevels;

  @override
  Widget build(BuildContext context) {
    final levels = _levels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Adventure'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final levelName = levels[index];
          return Card(
            child: ListTile(
              title: Text('Livello ${index + 1}'),
              subtitle: Text(levelName),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _startLevel(context, levels, index),
            ),
          );
        },
      ),
    );
  }

  void _startLevel(BuildContext context, List<String> levels, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PixelAdventureGameScreen(
          levels: levels,
          initialIndex: index,
        ),
      ),
    );
  }
}

class PixelAdventureGameScreen extends ConsumerStatefulWidget {
  const PixelAdventureGameScreen({
    super.key,
    required this.levels,
    required this.initialIndex,
  });

  final List<String> levels;
  final int initialIndex;

  @override
  ConsumerState<PixelAdventureGameScreen> createState() =>
      _PixelAdventureGameScreenState();
}

class _PixelAdventureGameScreenState
    extends ConsumerState<PixelAdventureGameScreen> {
  late final PixelAdventure _game;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    final selectedCharacter =
        profile?.avatarCharacterForGame(pixelAdventureGameId) ??
            profile?.avatarCharacter ??
            pixelAdventureAvatarOptions.first.character;
    _game = PixelAdventure(
      levels: widget.levels,
      initialLevelIndex: widget.initialIndex,
      player: Player(character: selectedCharacter),
      showControls: true,
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF211F30),
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) => _HudOverlay(
                game: game as PixelAdventure,
                formatTime: _formatTime,
                onExit: () => Navigator.of(context).pop(),
              ),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }

  String _formatTime(double seconds) {
    final rawTotal = seconds.ceil();
    final total = rawTotal < 0
        ? 0
        : (rawTotal > 9999 ? 9999 : rawTotal);
    final minutes = total ~/ 60;
    final secs = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({
    required this.game,
    required this.formatTime,
    required this.onExit,
  });

  final PixelAdventure game;
  final String Function(double) formatTime;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: game.timeNotifier,
                    builder: (_, value, __) => Text(
                      'Tempo: ${formatTime(value)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ValueListenableBuilder<int>(
                    valueListenable: game.scoreNotifier,
                    builder: (_, score, __) => Text(
                      'Punti: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ValueListenableBuilder<GameStatus>(
          valueListenable: game.statusNotifier,
          builder: (context, status, _) {
            if (status != GameStatus.timeUp) {
              return const SizedBox.shrink();
            }
            return Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tempo scaduto!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onExit,
                      child: const Text('Torna al menu'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
