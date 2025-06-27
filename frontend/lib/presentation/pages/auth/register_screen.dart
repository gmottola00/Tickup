import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        final accessToken = session.accessToken;
        // Chiamata al tuo backend FastAPI per creare app_user
        final res = await http.post(
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
        print("Status: ${res.statusCode}");
        print("Body: ${res.body}");
        if (res.statusCode == 200 || res.statusCode == 201) {
          context.go('/pools'); // ✅ naviga se tutto ok
        } else {
          throw Exception("Errore backend: ${res.body}");
        }
      } else {
        throw Exception("Registrazione fallita. Controlla email e password.");
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
