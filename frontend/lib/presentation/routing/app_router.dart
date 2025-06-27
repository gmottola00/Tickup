import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/pages/splash/splash_screen.dart';
import 'package:tickup/presentation/pages/auth/login_screen.dart';
import 'package:tickup/presentation/pages/auth/register_screen.dart';
import 'package:tickup/presentation/pages/pools/pools_screen.dart';
import 'package:tickup/presentation/pages/prize/prize_page.dart';
import 'package:tickup/presentation/pages/games/game_launcher.dart';
import 'package:tickup/presentation/pages/games/game_runner.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/games',
      builder: (context, state) => const GameLauncher(),
    ),
    GoRoute(
      path: '/games/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        return GameRunner(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/pools',
      builder: (context, state) => const PoolsScreen(),
    ),
    GoRoute(
      path: '/prize',
      builder: (context, state) => const PrizePage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);
