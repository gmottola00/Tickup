import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:tickup/presentation/routing/app_router.dart';

class SkillWinApp extends StatelessWidget {
  const SkillWinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkillWin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
