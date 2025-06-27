import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> login() async {
    final supabase = Supabase.instance.client;

    final response = await supabase.auth.signInWithPassword(
      email: emailController.text,
      password: passwordController.text,
    );

    final user = response.user;
    final session = response.session;

    if (user != null && session != null) {
      final accessToken = session.accessToken;

      // Chiamata al tuo backend per creare app_user
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nickname': nicknameController.text,
          'avatar_url': avatarUrlController.text.isNotEmpty
              ? avatarUrlController.text
              : null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        context.go('/pools');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Errore nella creazione utente: ${response.body}')),
        );
      }

      context.go('/pools'); // naviga se tutto ok
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login fallito')),
      );
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
                onPressed: login,
                child: const Text('Login'),
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
