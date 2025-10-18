import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/presentation/pages/auth/login_screen.dart';
import 'package:tickup/presentation/pages/auth/register_screen.dart';
import 'package:tickup/presentation/pages/home/home_screen.dart';
import 'package:tickup/presentation/pages/games/game_launcher.dart';
import 'package:tickup/presentation/pages/games/game_runner.dart';
import 'package:tickup/presentation/pages/profile/profile_screen.dart';
import 'package:tickup/presentation/pages/profile/profile_edit_page.dart';
import 'package:tickup/presentation/pages/prize/prize_page.dart';
import 'package:tickup/presentation/pages/prize/prize_details_page.dart';
import 'package:tickup/presentation/pages/prize/my_prizes_page.dart';
import 'package:tickup/presentation/pages/pool/pool_create_page.dart';
import 'package:tickup/presentation/pages/pool/pool_details_page.dart';
import 'package:tickup/presentation/pages/pool/my_pools_page.dart';
import 'package:tickup/presentation/pages/pool/liked_pools_page.dart';
import 'package:tickup/presentation/pages/purchase/my_tickets_page.dart';
import 'package:tickup/presentation/pages/purchase/purchase_create_page.dart';
import 'package:tickup/presentation/pages/purchase/purchase_page_args.dart';
import 'package:tickup/presentation/pages/shell/main_shell.dart';
import 'package:tickup/presentation/pages/error/error_screen.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/core/utils/logger.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/pages/wallet/wallet_overview_page.dart';
import 'package:tickup/presentation/pages/wallet/wallet_topups_page.dart';
import 'package:tickup/presentation/pages/wallet/wallet_topup_create_page.dart';
import 'package:tickup/presentation/features/tanks_unity/tanks_unity_screen.dart';

// Provider per il router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home,
    debugLogDiagnostics: true,
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final location = state.uri.toString();

      Logger.debug(
          'Navigation redirect - Location: $location, Auth: $isAuthenticated');

      // Public routes that don't require authentication
      final publicRoutes = <String>{
        AppRoute.splash,
        AppRoute.login,
        AppRoute.register,
      };
      final isPublicRoute =
          publicRoutes.any((route) => location.startsWith(route));

      // If user is not authenticated and route is not public -> go to login
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoute.login;
      }

      // If user is authenticated and tries to hit auth routes -> send to home
      if (isAuthenticated &&
          (location == AppRoute.login || location == AppRoute.register)) {
        return AppRoute.home;
      }

      return null;
    },
    routes: [
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

      // Prize single page (create/update)
      GoRoute(
        path: AppRoute.prize,
        name: 'prize',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PrizePage(),
        ),
      ),

      // My Prizes (owned by current user)
      GoRoute(
        path: AppRoute.myPrizes,
        name: 'my-prizes',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MyPrizesPage(),
        ),
      ),

      // My Pools (owned by current user)
      GoRoute(
        path: AppRoute.myPools,
        name: 'my-pools',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MyPoolsPage(),
        ),
      ),

      // Liked Pools (favoriti dall'utente corrente)
      GoRoute(
        path: AppRoute.myLikedPools,
        name: 'my-liked-pools',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LikedPoolsPage(),
        ),
      ),

      // Pools joined by current user (via tickets)
      GoRoute(
        path: AppRoute.myTickets,
        name: 'my-tickets',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MyTicketsPage(),
        ),
      ),

      // Wallet
      GoRoute(
        path: AppRoute.wallet,
        name: 'wallet',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WalletOverviewPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.walletTopups,
        name: 'wallet-topups',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WalletTopupsPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.walletTopupCreate,
        name: 'wallet-topup-create',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const WalletTopupCreatePage(),
        ),
      ),

      // Prize Details (top-level)
      GoRoute(
        path: '/prizes/:prizeId',
        name: 'prize-details',
        pageBuilder: (context, state) {
          final prizeId = state.pathParameters['prizeId']!;
          final extra = state.extra;
          return MaterialPage(
            key: state.pageKey,
            child: PrizeDetailsPage(
              prizeId: prizeId,
              initial: extra is Prize ? extra : null,
            ),
          );
        },
      ),

      // Create Pool for prize
      GoRoute(
        path: '/prizes/:prizeId/create-pool',
        name: 'create-pool',
        pageBuilder: (context, state) {
          final prizeId = state.pathParameters['prizeId']!;
          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: PoolCreatePage(prizeId: prizeId),
          );
        },
      ),

      // Pool Details (top-level)
      GoRoute(
        path: '/pools/:poolId',
        name: 'pool-details',
        pageBuilder: (context, state) {
          final poolId = state.pathParameters['poolId']!;
          final extra = state.extra;
          return MaterialPage(
            key: state.pageKey,
            child: PoolDetailsPage(
              poolId: poolId,
              initial: extra is RafflePool ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/pools/:poolId/purchase',
        name: 'pool-purchase',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is PurchasePageArgs) {
            return MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: PurchaseCreatePage(args: extra),
            );
          }
          return MaterialPage(
            key: state.pageKey,
            child: ErrorScreen(
              error: 'Dati acquisto mancanti',
            ),
          );
        },
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home Tab
          GoRoute(
            path: AppRoute.home,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          // Games Tab
          GoRoute(
            path: AppRoute.games,
            name: 'games',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const GameLauncher(),
            ),
          ),

          // Profile Tab
          GoRoute(
            path: AppRoute.profile,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: AppRoute.profileEdit,
        name: 'profile-edit',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const ProfileEditPage(),
        ),
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

      GoRoute(
        path: '/unity/tanks',
        name: 'unity-tanks',
        pageBuilder: (context, state) {
          final scene = state.uri.queryParameters['scene'];
          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: TanksUnityScreen(initialScene: scene),
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
