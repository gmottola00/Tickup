import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi richiesti')),
      );
      return;
    }

    setState(() => isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        final res = await DioClient().post(
          'users/me',
          data: {
            'nickname': nickname.isEmpty ? null : nickname,
          },
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          if (mounted) context.go(AppRoute.home);
        } else {
          throw Exception('Errore backend: ${res.statusCode}');
        }
      } else if (user != null && session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrazione avviata. Controlla la tua email per confermare l\'account',
              ),
            ),
          );
          context.go(AppRoute.login);
        }
      } else {
        throw Exception('Registrazione fallita.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? theme.colorScheme.surface.withOpacity(0.9)
        : theme.colorScheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary.withOpacity(0.85),
                theme.colorScheme.primary.withOpacity(0.65),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
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
                                'Crea il tuo account',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Compila i campi per iniziare a vendere e gestire i tuoi pool.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                theme,
                                controller: nicknameController,
                                label: 'Nickname',
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                theme,
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.alternate_email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  filled: true,
                                  fillColor: theme
                                      .colorScheme.surfaceVariant
                                      .withOpacity(0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: obscurePassword
                                        ? 'Mostra password'
                                        : 'Nascondi password',
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setState(
                                      () => obscurePassword = !obscurePassword,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: isLoading ? null : register,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
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
                                    : const Text('Registrati'),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go(AppRoute.login),
                                child: const Text(
                                  'Hai già un account? Accedi',
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
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white.withOpacity(0.18),
          child: Icon(
            Icons.emoji_events_outlined,
            size: 42,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Unisciti a TickUp',
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
          'Crea il tuo account e inizia a gestire premi e pool.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
