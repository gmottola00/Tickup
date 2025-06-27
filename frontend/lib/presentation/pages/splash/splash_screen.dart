import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay opzionale
    // Future.delayed(const Duration(seconds: 2), () {
    //   context.go('/login');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SkillWin Splash'),
            const SizedBox(height: 24),
            _buildPrizeButton(context),
            _buildLoginButton(context),
            _buildGamesButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/prize'),
      child: const Text('Vai alla pagina Premio'),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/login'),
      child: const Text('Vai alla pagina Login'),
    );
  }

  Widget _buildGamesButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/games'),
      child: const Text('Vai alla pagina dei Giochi'),
    );
  }
}
