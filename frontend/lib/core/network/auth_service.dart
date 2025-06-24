/// MOCK di servizio auth – sostituisci con Supabase o altro.
///
/// Responsabilità:
/// • tenere in memoria (o secure storage) l’access token
/// • rinfrescare il token quando scade
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  String? _accessToken;

  /// Ritorna il token, se presente.
  Future<String?> getAccessToken() async => _accessToken;

  /// Esempio di refresh: falsa risposta di successo.
  Future<bool> refreshToken() async {
    // TODO: integra la tua logica (es. Supabase refresh)
    await Future.delayed(const Duration(milliseconds: 300));
    _accessToken = 'new_fake_token';
    return true;
  }

  /// Solo per test locale: imposta un token fittizio.
  void setToken(String token) => _accessToken = token;
}
