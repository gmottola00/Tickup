import 'package:flutter/material.dart';
import 'game_result.dart';

/// Interfaccia che tutti i giochi devono implementare
abstract class GameInterface {
  /// Avvia il gioco e restituisce un GameResult al termine
  Future<GameResult?> startGame(BuildContext context);
}
