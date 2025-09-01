import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/app.dart';
import 'package:tickup/core/config/env_config.dart';
import 'package:tickup/core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup sistema
  await _initializeApp();

  runApp(
    ProviderScope(
      observers: [RiverpodLogger()],
      child: const SkillWinApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    // Imposta orientamento (solo portrait per mobile)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Inizializza Supabase con configurazione da env
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      debug: EnvConfig.isDevelopment,
    );

    Logger.info('App initialized successfully');
  } catch (e, stack) {
    Logger.error('Failed to initialize app', error: e, stackTrace: stack);
    rethrow;
  }
}
