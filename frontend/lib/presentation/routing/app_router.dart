import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/pages/splash/splash_screen.dart';
import 'package:tickup/presentation/pages/auth/login_screen.dart';
import 'package:tickup/presentation/pages/pools/pools_screen.dart';
import 'package:tickup/presentation/pages/prize/prize_page.dart';

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
      path: '/pools',
      builder: (context, state) => const PoolsScreen(),
    ),
    GoRoute(
      path: '/prize',
      builder: (context, state) => const PrizePage(),
    ),
  ],
);
