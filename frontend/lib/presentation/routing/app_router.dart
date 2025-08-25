import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/pages/home/home_screen.dart';
import 'package:tickup/presentation/pages/auth/login_screen.dart';
import 'package:tickup/presentation/pages/auth/register_screen.dart';
import 'package:tickup/presentation/pages/prize/prize_page.dart';
import 'package:tickup/presentation/pages/games/game_launcher.dart';
import 'package:tickup/presentation/pages/games/game_runner.dart';
import 'package:tickup/presentation/pages/shell/shell_page.dart';
import 'package:tickup/presentation/routing/app_route.dart';

final appRouter = GoRouter(
  initialLocation: AppRoute.dashboard,
  routes: [
    GoRoute(
      path: AppRoute.login,
      builder: (context, _) => const LoginScreen(),
    ),
    // Shell con Bottom Navigation (nessun parametro "path" richiesto)
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: '/', // «/» (GameLauncher)
          builder: (context, _) => const GameLauncher(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, _) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoute.register, // '/register'
          builder: (context, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoute.prize, // '/prize'
          builder: (context, _) => const PrizePage(),
        ),
      ],
    ),
    // GameRunner fuori dal guscio: niente Bottom Nav mentre si gioca
    GoRoute(
      path: '/games/:gameId',
      builder: (context, state) {
        final id = state.pathParameters['gameId']!;
        return GameRunner(gameId: id);
      },
    ),
  ],
);
