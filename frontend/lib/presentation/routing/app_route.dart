/// Percorsi dichiarati come costanti per evitare *typo*.
class AppRoute {
  static const dashboard = '/';
  static const register = '/register';
  static const prize = '/prize';
  static const login = '/login';
  static String game(String id) => '/games/$id';
}
