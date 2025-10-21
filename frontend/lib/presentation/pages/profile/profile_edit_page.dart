import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/presentation/features/profile/avatar_catalog.dart';
import 'package:tickup/presentation/features/profile/profile_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _initializing = true;
  bool _saving = false;
  String? _initialNickname;
  String? _initialEmail;
  String? _pendingEmail;
  DateTime? _pendingEmailRequestedAt;
  GameAvatarOption _pixelAdventureAvatar =
      defaultAvatarForGame(pixelAdventureGameId);
  GameAvatarOption? _initialPixelAdventureAvatar;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final profile = ref.read(userProfileProvider);
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _initialNickname = profile?.nickname ??
          (user?.userMetadata?['nickname'] as String?) ??
          '';
      _initialEmail = profile?.email ?? user?.email ?? '';
      _pendingEmail = profile?.pendingEmail;
      _pendingEmailRequestedAt = profile?.pendingEmailRequestedAt;
      _nicknameController.text = _initialNickname ?? '';
      _emailController.text = profile?.pendingEmail ?? _initialEmail ?? '';
      final pixelMetadata = profile?.gameAvatars[pixelAdventureGameId];
      final selectedAvatar = resolveAvatarSelection(
            pixelAdventureGameId,
            optionId: pixelMetadata?['id'] as String?,
            character: (pixelMetadata?['character'] ??
                profile?.avatarCharacter) as String?,
            asset:
                (pixelMetadata?['asset'] ?? profile?.avatarAsset) as String?,
          ) ??
          defaultAvatarForGame(pixelAdventureGameId);
      _pixelAdventureAvatar = selectedAvatar;
      _initialPixelAdventureAvatar = selectedAvatar;
      _initializing = false;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showMessage('Utente non autenticato, esegui nuovamente il login.');
      return;
    }

    final newNickname = _nicknameController.text.trim();
    final newEmail = _emailController.text.trim();
    final currentEmail = user.email ?? '';

    final metadata =
        Map<String, dynamic>.from(user.userMetadata ?? <String, dynamic>{});
    final oldNickname = (_initialNickname ?? '').trim();

    final nicknameChanged = newNickname != oldNickname;
    final emailChanged = newEmail.isNotEmpty && newEmail != currentEmail;
    final selectedAvatar = _pixelAdventureAvatar;
    final avatarChanged = _initialPixelAdventureAvatar == null ||
        selectedAvatar.id != _initialPixelAdventureAvatar!.id;

    if (!emailChanged) {
      final pending = metadata['pending_email'];
      if (pending != null && pending == currentEmail) {
        metadata.remove('pending_email');
        metadata.remove('pending_email_requested_at');
      }
    }

    if (!nicknameChanged && !emailChanged && !avatarChanged) {
      _showMessage('Nessuna modifica da salvare.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      metadata['nickname'] = newNickname;
      if (avatarChanged) {
        final gameAvatars =
            Map<String, dynamic>.from(metadata['game_avatars'] as Map? ?? {});
        gameAvatars[pixelAdventureGameId] = {
          'id': selectedAvatar.id,
          'character': selectedAvatar.character,
          'asset': selectedAvatar.asset,
        };
        metadata['game_avatars'] = gameAvatars;
        metadata['avatar_character'] = selectedAvatar.character;
        metadata['avatar_asset'] = selectedAvatar.asset;
        metadata['avatar_url'] = selectedAvatar.asset;
      }
      if (emailChanged) {
        metadata['pending_email'] = newEmail;
        metadata['pending_email_requested_at'] =
            DateTime.now().toUtc().toIso8601String();
      }

      final response =
          await Supabase.instance.client.auth.updateUser(UserAttributes(
        data: metadata,
        email: emailChanged ? newEmail : null,
      ));

      await AuthService.instance.syncFromSupabase();
      ref.invalidate(userProfileProvider);

      final updatedUser = response.user ??
          Supabase.instance.client.auth.currentUser ??
          user;
      final updatedProfile =
          updatedUser != null ? UserProfile.fromUser(updatedUser) : null;
      final updatedAvatar = (() {
        final meta = updatedProfile?.gameAvatars[pixelAdventureGameId];
        return resolveAvatarSelection(
              pixelAdventureGameId,
              optionId: meta?['id'] as String?,
              character: (meta?['character'] ??
                  updatedProfile?.avatarCharacter) as String?,
              asset:
                  (meta?['asset'] ?? updatedProfile?.avatarAsset) as String?,
            ) ??
            selectedAvatar;
      })();

      setState(() {
        _initialNickname = updatedProfile?.nickname ?? newNickname;
        _initialEmail = updatedProfile?.email ?? updatedUser?.email ?? newEmail;
        _pendingEmail = updatedProfile?.pendingEmail ??
            (emailChanged ? newEmail : null);
        _pendingEmailRequestedAt = updatedProfile?.pendingEmailRequestedAt ??
            (emailChanged ? DateTime.now() : null);
        _pixelAdventureAvatar = updatedAvatar;
        _initialPixelAdventureAvatar = updatedAvatar;
        _saving = false;
      });

      if (!mounted) return;

      final successMessage = emailChanged
          ? 'Ti abbiamo inviato un\'email di conferma a $newEmail.'
          : 'Profilo aggiornato con successo.';
      _showMessage(successMessage);
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _saving = false);
      _showMessage(_mapError(error));
    }
  }

  Future<void> _cancelPendingEmail() async {
    if (_saving || _pendingEmail == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final metadata =
        Map<String, dynamic>.from(user.userMetadata ?? <String, dynamic>{});
    metadata.remove('pending_email');
    metadata.remove('pending_email_requested_at');
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final response = await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: metadata));
      await AuthService.instance.syncFromSupabase();
      ref.invalidate(userProfileProvider);
      final updatedUser = response.user ??
          Supabase.instance.client.auth.currentUser ??
          user;
      final updatedProfile =
          updatedUser != null ? UserProfile.fromUser(updatedUser) : null;
      setState(() {
        _pendingEmail = updatedProfile?.pendingEmail;
        _pendingEmailRequestedAt = updatedProfile?.pendingEmailRequestedAt;
        _emailController.text = updatedProfile?.email ?? updatedUser?.email ?? '';
        _saving = false;
      });
      if (!mounted) return;
      _showMessage('Richiesta di cambio email annullata.');
    } catch (error) {
      setState(() => _saving = false);
      _showMessage(_mapError(error));
    }
  }

  String _mapError(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return 'Impossibile aggiornare il profilo. Riprova tra qualche minuto.';
  }

  String _pendingDescription() {
    if (_pendingEmail == null) return '';
    final sentAt = _pendingEmailRequestedAt;
    if (sentAt == null) {
      return 'Abbiamo inviato un\'email di conferma a $_pendingEmail.';
    }
    final local = sentAt.toLocal();
    final formatted =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} alle ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return 'Abbiamo inviato un\'email di conferma a $_pendingEmail il $formatted.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica profilo'),
      ),
      body: Stack(
        children: [
          if (_initializing)
            const Center(child: CircularProgressIndicator())
          else
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dati account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              labelText: 'Nickname',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inserisci un nickname.';
                              }
                              if (value.trim().length < 3) {
                                return 'Il nickname deve contenere almeno 3 caratteri.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inserisci un indirizzo email valido.';
                              }
                              final emailRegex = RegExp(
                                  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$");
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Formato email non valido.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avatar Pixel Adventure',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scegli come apparirai in Pixel Adventure.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          _GameAvatarSelector(
                            options: pixelAdventureAvatarOptions,
                            selected: _pixelAdventureAvatar,
                            onSelected: (option) {
                              setState(() => _pixelAdventureAvatar = option);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_pendingEmail != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: theme.colorScheme.secondaryContainer
                          .withOpacity(0.7),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.hourglass_top,
                                    color: theme.colorScheme.onSecondaryContainer),
                                const SizedBox(width: 8),
                                Text(
                                  'Email in attesa di conferma',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _pendingDescription(),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _saving ? null : _cancelPendingEmail,
                              icon: const Icon(Icons.close),
                              label: const Text('Annulla richiesta'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salva modifiche'),
                  ),
                ],
              ),
            ),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _GameAvatarSelector extends StatelessWidget {
  const _GameAvatarSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<GameAvatarOption> options;
  final GameAvatarOption selected;
  final ValueChanged<GameAvatarOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          _AvatarOptionTile(
            option: option,
            isSelected: option.id == selected.id,
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}

class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final GameAvatarOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final backgroundColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.15)
        : theme.colorScheme.surfaceVariant.withOpacity(0.35);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 3 : 1,
          ),
          color: backgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: Image.asset(
                option.asset,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
