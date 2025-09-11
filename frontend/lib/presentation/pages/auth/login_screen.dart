import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/core/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  final avatarUrlController = TextEditingController();
  bool _loading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    Logger.debug('Login pressed', data: {'email': email.isNotEmpty});

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci email e password')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      Logger.debug('Supabase signInWithPassword start');
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      final session = response.session;
      Logger.debug('Supabase signIn result', data: {
        'hasUser': user != null,
        'hasSession': session != null,
      });

      if (user != null && session != null) {
        // Assicura che il token sia disponibile nel DioClient
        await AuthService.instance.syncFromSupabase();
        // Crea app_user in backend (idempotente)
        try {
          final res = await DioClient().post(
            '/users/me',
            data: {
              'nickname': nicknameController.text,
              'avatar_url': avatarUrlController.text.isNotEmpty
                  ? avatarUrlController.text
                  : null,
            },
          );
          Logger.debug('Backend /users/me response', data: res.statusCode);
        } on Exception catch (e) {
          final code = e.toString();
          Logger.warning('Backend /users/me error', data: code);
          // Se l'utente esiste già, trattiamo come successo
          if (code != 400 && code != 409) rethrow;
        }

        if (!mounted) return;
        context.go(AppRoute.home);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Credenziali non valide o email non confermata')),
        );
      }
    } catch (e, st) {
      Logger.error('Login failed', error: e, stackTrace: st as StackTrace?);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore login: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              TextField(
                controller: avatarUrlController,
                decoration:
                    const InputDecoration(labelText: 'Avatar URL (opzionale)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              const Divider(height: 30),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text("Non hai un account? Registrati"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
