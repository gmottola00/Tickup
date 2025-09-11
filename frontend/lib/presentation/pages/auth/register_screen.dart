import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  final avatarUrlController = TextEditingController();
  bool isLoading = false;

  Future<void> register() async {
    setState(() => isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = response.user;
      final session = response.session;
      print("Signup response: $response");
      print("User: ${response.user}");
      print("Session: ${response.session}");
      if (user != null && session != null) {
        print("Entrato");
        // Crea app_user su backend (usa token iniettato da DioClient)
        final res = await DioClient().post(
          '/users/me',
          data: {
            'nickname': nicknameController.text,
            'avatar_url': avatarUrlController.text.isNotEmpty
                ? avatarUrlController.text
                : null,
          },
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          context.go('/');
        } else {
          throw Exception("Errore backend: ${res.statusCode}");
        }
      } else if (user != null && session == null) {
        // Email confirmation required: Supabase ha creato l'utente ma non ha aperto la sessione
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrazione avviata. Controlla la tua email per confermare l\'account',
              ),
            ),
          );
        }
        // Vai alla pagina di login
        if (mounted) context.go('/home');
      } else {
        throw Exception('Registrazione fallita.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrati')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const Divider(height: 30),
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
              onPressed: isLoading ? null : register,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}
