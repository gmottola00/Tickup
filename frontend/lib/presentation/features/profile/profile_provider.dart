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
    Map<String, dynamic>? rawMetadata,
  }) : metadata = UnmodifiableMapView(rawMetadata ?? const {});

  final String id;
  final String email;
  final String? nickname;
  final bool emailVerified;
  final String? pendingEmail;
  final DateTime? pendingEmailRequestedAt;
  final Map<String, dynamic> metadata;

  factory UserProfile.fromUser(User user) {
    final metadata = _normalizedMetadata(user.userMetadata);
    final rawPendingEmail = metadata['pending_email'] as String?;
    final resolvedPendingEmail =
        (rawPendingEmail != null && rawPendingEmail == (user.email ?? ''))
            ? null
            : rawPendingEmail;
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      nickname: metadata['nickname'] as String?,
      emailVerified: user.emailConfirmedAt != null,
      pendingEmail: resolvedPendingEmail,
      pendingEmailRequestedAt:
          _tryParseDate(metadata['pending_email_requested_at']),
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
}

final userProfileProvider = Provider<UserProfile?>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return UserProfile.fromUser(user);
});
