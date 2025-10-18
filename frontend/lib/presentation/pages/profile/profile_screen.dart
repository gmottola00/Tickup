import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/providers/theme_provider.dart';
import 'package:tickup/presentation/features/profile/profile_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final profile = ref.watch(userProfileProvider);
    final displayName = (profile?.nickname?.trim().isNotEmpty ?? false)
        ? profile!.nickname!.trim()
        : 'Utente Tickup';
    final email =
        profile?.email.isNotEmpty == true ? profile!.email : 'guest@example.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _signOut(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              )
            ],
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium,
                ),
                if (profile?.pendingEmail != null) ...[
                  const SizedBox(height: 12),
                  Chip(
                    backgroundColor:
                        theme.colorScheme.secondaryContainer.withOpacity(0.6),
                    avatar: const Icon(Icons.hourglass_top, size: 18),
                    label: Text(
                      'Email in attesa di conferma: ${profile!.pendingEmail}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tema scuro'),
                  subtitle: const Text('Attiva/disattiva modalità scura'),
                  value: mode == ThemeMode.dark,
                  onChanged: (_) {
                    final notifier = ref.read(themeModeProvider.notifier);
                    notifier.setTheme(mode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark);
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: const Text('I miei premi'),
                  subtitle: const Text('Elenco dei premi che hai creato'),
                  onTap: () => context.push(AppRoute.myPrizes),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: const Text('I miei pool'),
                  subtitle: const Text('Elenco dei pool che hai creato'),
                  onTap: () => context.push(AppRoute.myPools),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_activity_outlined),
                  title: const Text('I miei ticket'),
                  subtitle: const Text('Pool a cui stai partecipando'),
                  onTap: () => context.push(AppRoute.myTickets),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('I miei preferiti'),
                  subtitle: const Text('Pool che ti piacciono'),
                  onTap: () => context.push(AppRoute.myLikedPools),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Il mio wallet'),
                  subtitle: const Text('Saldo, movimenti e ricariche'),
                  onTap: () => context.push(AppRoute.wallet),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Impostazioni'),
                  subtitle: const Text('Preferenze account e privacy'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modifica profilo'),
                  subtitle: const Text('Aggiorna nickname e indirizzo email'),
                  onTap: () async {
                    final updated =
                        await context.push<bool>(AppRoute.profileEdit);
                    if (updated == true) {
                      ref.invalidate(userProfileProvider);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          )
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout effettuato')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel logout: $e')),
        );
      }
    }
  }
}
