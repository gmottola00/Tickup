class AppRoute {
  // Prevent instantiation
  AppRoute._();

  // Auth & Onboarding
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Main Navigation (con bottom nav)
  static const games = '/games';
  static const prizes = '/prizes';
  static const leaderboard = '/leaderboard';
  static const profile = '/profile';

  // Sub-routes
  static const profileEdit = '/profile/edit';
  static const profileSettings = '/profile/settings';

  // Game specific (senza bottom nav)
  static String game(String id, {String? difficulty}) {
    final base = '/game/$id';
    if (difficulty != null) {
      return '$base?difficulty=$difficulty';
    }
    return base;
  }

  static String prizeDetails(String id) => '/prizes/$id';

  // Utility methods
  static bool isAuthRoute(String path) {
    return path == login || path == register || path == forgotPassword;
  }

  static bool isMainRoute(String path) {
    return path == games ||
        path == prizes ||
        path == leaderboard ||
        path == profile;
  }
}
