import 'package:flutter/material.dart';
import 'presentation/routing/app_router.dart';

class SkillWinApp extends StatelessWidget {
  const SkillWinApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug routes all'avvio
    for (final route in appRouter.configuration.routes) {
      debugPrint('📍 Route disponibile: ${route.toString()}');
    }
    return MaterialApp.router(
      title: 'SkillWin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: appRouter,
    );
  }
}
