import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/presentation/pages/auth/login_screen.dart';
import 'package:tickup/presentation/pages/auth/register_screen.dart';
import 'package:tickup/presentation/pages/games/game_launcher.dart';
import 'package:tickup/presentation/pages/games/game_runner.dart';
// import 'package:tickup/presentation/pages/profile/profile_screen.dart';
// import 'package:tickup/presentation/pages/prizes/prizes_screen.dart';
// import 'package:tickup/presentation/pages/prizes/prize_details_screen.dart';
// import 'package:tickup/presentation/pages/leaderboard/leaderboard_screen.dart';
import 'package:tickup/presentation/pages/shell/main_shell.dart';
import 'package:tickup/presentation/pages/splash/splash_screen.dart';
import 'package:tickup/presentation/pages/error/error_screen.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/core/utils/logger.dart';

// Provider per il router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.splash,
    debugLogDiagnostics: true,
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) {
      return null;
      // final session = Supabase.instance.client.auth.currentSession;
      // final isAuthenticated = session != null;
      // final location = state.uri.toString();

      // Logger.debug(
      //     'Navigation redirect - Location: $location, Auth: $isAuthenticated');

      // // Gestione splash screen
      // if (location == AppRoute.splash) {
      //   return null; // Lascia gestire alla splash
      // }

      // // Route pubbliche
      // final publicRoutes = [
      //   AppRoute.login,
      //   AppRoute.register,
      // ];

      // final isPublicRoute =
      //     publicRoutes.any((route) => location.startsWith(route));

      // // Redirect logic
      // if (!isAuthenticated && !isPublicRoute) {
      //   return AppRoute.login;
      // }

      // if (isAuthenticated && isPublicRoute) {
      //   return AppRoute.games;
      // }

      // return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoute.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoute.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Games Tab
          GoRoute(
            path: AppRoute.games,
            name: 'games',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const GameLauncher(),
            ),
          ),

          // // Prizes Tab
          // GoRoute(
          //   path: AppRoute.prizes,
          //   name: 'prizes',
          //   pageBuilder: (context, state) => NoTransitionPage(
          //     key: state.pageKey,
          //     child: const PrizesScreen(),
          //   ),
          //   routes: [
          //     GoRoute(
          //       path: ':prizeId',
          //       name: 'prize-details',
          //       builder: (context, state) {
          //         final prizeId = state.pathParameters['prizeId']!;
          //         return PrizeDetailsScreen(prizeId: prizeId);
          //       },
          //     ),
          //   ],
          // ),

          // // Leaderboard Tab
          // GoRoute(
          //   path: AppRoute.leaderboard,
          //   name: 'leaderboard',
          //   pageBuilder: (context, state) => NoTransitionPage(
          //     key: state.pageKey,
          //     child: const LeaderboardScreen(),
          //   ),
          // ),

          // // Profile Tab
          // GoRoute(
          //   path: AppRoute.profile,
          //   name: 'profile',
          //   pageBuilder: (context, state) => NoTransitionPage(
          //     key: state.pageKey,
          //     child: const ProfileScreen(),
          //   ),
          //   routes: [
          //     GoRoute(
          //       path: 'edit',
          //       name: 'profile-edit',
          //       builder: (context, state) => const ProfileEditScreen(),
          //     ),
          //     GoRoute(
          //       path: 'settings',
          //       name: 'settings',
          //       builder: (context, state) => const SettingsScreen(),
          //     ),
          //   ],
          // ),
        ],
      ),

      // Game Runner (Fullscreen)
      GoRoute(
        path: '/game/:gameId',
        name: 'game-runner',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId']!;

          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: GameRunner(
              gameId: gameId,
            ),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(
        error: state.error,
        onRetry: () => context.go(AppRoute.games),
      ),
    ),
  );
});

// Router Notifier per ascoltare cambiamenti di stato
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Ascolta i cambiamenti di autenticazione di Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
