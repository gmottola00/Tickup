/// MOCK di servizio auth – sostituisci con Supabase o altro.
///
/// Responsabilità:
/// • tenere in memoria (o secure storage) l’access token
/// • rinfrescare il token quando scade
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._() {
    // Inizializza da sessione corrente (se presente)
    final session = Supabase.instance.client.auth.currentSession;
    _accessToken = session?.accessToken;

    // Ascolta i cambi di sessione per mantenere aggiornato il token
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final next = event.session?.accessToken;
      if (next != null) {
        _accessToken = next;
      } else {
        _accessToken = null;
      }
    });
  }

  static final instance = AuthService._();

  String? _accessToken;

  Future<String?> getAccessToken() async => _accessToken;

  void setToken(String token) => _accessToken = token;

  Future<bool> refreshToken() async {
    try {
      final current = Supabase.instance.client.auth.currentSession;
      if (current == null) return false;
      final res = await Supabase.instance.client.auth.refreshSession();
      final newToken = res.session?.accessToken;
      if (newToken != null) {
        _accessToken = newToken;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncFromSupabase() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) _accessToken = token;
  }
}
