import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/core/network/dio_client.dart';
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
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();
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
          await DioClient().post(
            'users/me',
            data: {
              'nickname': null,
              'avatar_url': null,
            },
          );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? theme.colorScheme.surface.withOpacity(0.92)
        : theme.colorScheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.85),
                theme.colorScheme.secondary.withOpacity(0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 24),
                      Card(
                        color: cardColor,
                        elevation: isDark ? 4 : 12,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Accedi a TickUp',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Inserisci le tue credenziali per continuare.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildEmailField(theme),
                              const SizedBox(height: 16),
                              _buildPasswordField(theme),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _loading ? null : login,
                                style: FilledButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Accedi'),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.go(AppRoute.register),
                                child: const Text(
                                  'Non hai un account? Registrati',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white.withOpacity(0.18),
          child: Icon(
            Icons.confirmation_num_outlined,
            size: 42,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bentornato!',
          style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Accedi per continuare a scoprire i premi.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.alternate_email_outlined),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Mostra password' : 'Nascondi password',
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }
}
