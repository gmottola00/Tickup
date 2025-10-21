import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.emailVerified,
    this.pendingEmail,
    this.pendingEmailRequestedAt,
    this.avatarCharacter,
    this.avatarAsset,
    Map<String, Map<String, dynamic>>? avatars,
    Map<String, dynamic>? rawMetadata,
  })  : metadata = UnmodifiableMapView(rawMetadata ?? const {}),
        gameAvatars =
            UnmodifiableMapView(avatars ?? const <String, Map<String, dynamic>>{});

  final String id;
  final String email;
  final String? nickname;
  final bool emailVerified;
  final String? pendingEmail;
  final DateTime? pendingEmailRequestedAt;
  final String? avatarCharacter;
  final String? avatarAsset;
  final Map<String, dynamic> metadata;
  final Map<String, Map<String, dynamic>> gameAvatars;

  factory UserProfile.fromUser(User user) {
    final metadata = _normalizedMetadata(user.userMetadata);
    final rawPendingEmail = metadata['pending_email'] as String?;
    final resolvedPendingEmail =
        (rawPendingEmail != null && rawPendingEmail == (user.email ?? ''))
            ? null
            : rawPendingEmail;
    final avatars = _normalizedAvatarMap(metadata['game_avatars']);
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      nickname: metadata['nickname'] as String?,
      emailVerified: user.emailConfirmedAt != null,
      pendingEmail: resolvedPendingEmail,
      pendingEmailRequestedAt:
          _tryParseDate(metadata['pending_email_requested_at']),
      avatarCharacter: metadata['avatar_character'] as String?,
      avatarAsset: metadata['avatar_asset'] as String?,
      avatars: avatars,
      rawMetadata: metadata,
    );
  }

  static Map<String, dynamic> _normalizedMetadata(Object? source) {
    if (source is Map<String, dynamic>) return Map<String, dynamic>.from(source);
    if (source is Map) {
      return Map<String, dynamic>.fromEntries(
        source.entries.map(
          (e) => MapEntry(e.key.toString(), e.value),
        ),
      );
    }
    return {};
  }

  static Map<String, Map<String, dynamic>> _normalizedAvatarMap(
      Object? source) {
    if (source is Map) {
      return Map<String, Map<String, dynamic>>.fromEntries(
        source.entries.map(
          (entry) => MapEntry(
            entry.key.toString(),
            _normalizedNested(entry.value),
          ),
        ),
      );
    }
    return {};
  }

  static Map<String, dynamic> _normalizedNested(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), e.value),
        ),
      );
    }
    return {};
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          .toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  String? avatarCharacterForGame(String gameId) {
    final entry = gameAvatars[gameId];
    final result = entry?['character'] ?? entry?['avatar_character'];
    return (result is String && result.trim().isNotEmpty)
        ? result
        : avatarCharacter;
  }

  String? avatarAssetForGame(String gameId) {
    final entry = gameAvatars[gameId];
    final result = entry?['asset'] ?? entry?['avatar_asset'];
    return (result is String && result.trim().isNotEmpty) ? result : avatarAsset;
  }
}

final userProfileProvider = Provider<UserProfile?>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return UserProfile.fromUser(user);
});
