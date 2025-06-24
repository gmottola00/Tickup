import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Supabase
  await Supabase.initialize(
    url: 'https://augoixjimymsaboihxcx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1Z29peGppbXltc2Fib2loeGN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwNDQ0ODMsImV4cCI6MjA2NDYyMDQ4M30.HtoG0b0Z_yztbiSgS4Zy7sx1gyzc4lp8zeJdadp0VpQ',
  );

  runApp(
    const ProviderScope(
      child: SkillWinApp(),
    ),
  );
}
