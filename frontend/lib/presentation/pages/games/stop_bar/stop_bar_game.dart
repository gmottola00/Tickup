import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/features/logic_games/stop_bar_logic.dart';

/// Widget UI del mini-gioco "Ferma la barra" (versione a tempo).
class StopBarGame extends StatefulWidget {
  const StopBarGame({Key? key}) : super(key: key);

  @override
  State<StopBarGame> createState() => _StopBarGameState();
}

class _StopBarGameState extends State<StopBarGame> {
  late final StopBarLogic logic;

  @override
  void initState() {
    super.initState();
    logic = StopBarLogic()..start();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ferma la barra')),
        body: Center(
          child: AnimatedBuilder(
            animation: logic,
            builder: (context, _) => logic.gameOver
                ? _buildEndScreen(context)
                : _buildGameScreen(context),
          ),
        ),
      );

  // ────────────────────────────────────────────────────────────
  // Schermata di gioco
  Widget _buildGameScreen(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer e punteggio
          Text(
            'Tempo: ${logic.remainingSeconds}s',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Punti: ${logic.score}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),

          // Barra con zona verde
          Stack(
            children: [
              Container(height: 50, width: 300, color: Colors.grey[300]),
              Positioned(
                left: 300 * StopBarLogic.greenStart,
                child: Container(
                  height: 50,
                  width:
                      300 * (StopBarLogic.greenEnd - StopBarLogic.greenStart),
                  color: Colors.green,
                ),
              ),
              Positioned(
                left: 300 * logic.position,
                child: Container(height: 50, width: 10, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Pulsante di TAP
          ElevatedButton(
            onPressed: logic.tap,
            child: const Text('STOP!'),
          ),
        ],
      );

  // ────────────────────────────────────────────────────────────
  // Schermata di fine partita
  Widget _buildEndScreen(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⏱️ Tempo scaduto!',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Punteggio finale: ${logic.score}',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: logic.restart,
            child: const Text('Gioca di nuovo'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/games'),
            child: const Text('Torna ai giochi'),
          ),
        ],
      );
}
