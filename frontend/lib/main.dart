import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Supabase
  await Supabase.initialize(
    url: 'https://<YOUR-PROJECT-REF>.supabase.co',
    anonKey: '<YOUR-ANON-KEY>',
  );

  runApp(const SkillWinApp());
}
