import 'package:flutter/material.dart';
import 'presentation/routing/app_router.dart';

class SkillWinApp extends StatelessWidget {
  const SkillWinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkillWin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: appRouter,
    );
  }
}
