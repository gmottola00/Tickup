import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

typedef BackendErrorActionCallback = FutureOr<void> Function(
  BuildContext context,
);

/// Utility per mostrare modali di errore coerenti quando le chiamate backend falliscono.
/// Permette di definire azioni contestuali (es. pulsanti personalizzati) in base
/// al tipo di errore ricevuto.
class BackendErrorAction {
  BackendErrorAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.closeOnTap = true,
  });

  final String label;
  final BackendErrorActionCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool closeOnTap;

  factory BackendErrorAction.dismiss({
    String label = 'Chiudi',
    IconData? icon,
    bool isPrimary = false,
  }) {
    return BackendErrorAction(
      label: label,
      icon: icon,
      isPrimary: isPrimary,
      onPressed: (_) {},
    );
  }
}

/// Mostra un dialog di errore con messaggio generato automaticamente in base
/// all'eccezione ricevuta (gestendo in modo particolare gli errori HTTP/Dio).
class BackendErrorDialog {
  const BackendErrorDialog._();

  static Future<void> show(
    BuildContext context, {
    required Object error,
    List<BackendErrorAction>? actions,
    String? title,
    String? message,
    bool barrierDismissible = true,
  }) async {
    final rootContext = context;
    final parsed = _ParsedBackendError.from(
      rootContext,
      error: error,
      overrideTitle: title,
      overrideMessage: message,
    );

    final effectiveActions = (actions == null || actions.isEmpty)
        ? <BackendErrorAction>[BackendErrorAction.dismiss()]
        : actions;

    await showDialog<void>(
      context: rootContext,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: parsed.iconBackground ??
                      theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  parsed.icon,
                  size: 24,
                  color: parsed.iconColor ?? theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  parsed.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parsed.statusCode != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Codice errore: ${parsed.statusCode}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                parsed.message,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ],
          ),
          actions: effectiveActions
              .map(
                (action) => _buildActionButton(
                  dialogContext: dialogContext,
                  parentContext: rootContext,
                  action: action,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  static Widget _buildActionButton({
    required BuildContext dialogContext,
    required BuildContext parentContext,
    required BackendErrorAction action,
  }) {
    Future<void> handleTap() async {
      if (action.closeOnTap) {
        Navigator.of(dialogContext).pop();
        await Future<void>.delayed(Duration.zero);
      }

      final result = action.onPressed(parentContext);
      if (result is Future) {
        await result;
      }
    }

    if (action.isPrimary) {
      return action.icon != null
          ? FilledButton.icon(
              onPressed: handleTap,
              icon: Icon(action.icon),
              label: Text(action.label),
            )
          : FilledButton(
              onPressed: handleTap,
              child: Text(action.label),
            );
    }

    return action.icon != null
        ? TextButton.icon(
            onPressed: handleTap,
            icon: Icon(action.icon),
            label: Text(action.label),
          )
        : TextButton(
            onPressed: handleTap,
            child: Text(action.label),
          );
  }
}

class _ParsedBackendError {
  _ParsedBackendError({
    required this.title,
    required this.message,
    required this.icon,
    this.iconColor,
    this.iconBackground,
    this.statusCode,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final int? statusCode;

  static _ParsedBackendError from(
    BuildContext context, {
    required Object error,
    String? overrideTitle,
    String? overrideMessage,
  }) {
    final theme = Theme.of(context);

    if (error is DioException) {
      final code = error.response?.statusCode;
      final title = overrideTitle ?? _titleForStatus(code);
      final message = overrideMessage ??
          _messageFromResponse(error) ??
          _defaultMessageForStatus(code);
      final icon = _iconForStatus(code);
      final (iconColor, iconBackground) = _iconColorsForStatus(theme, code);

      return _ParsedBackendError(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        iconBackground: iconBackground,
        statusCode: code,
      );
    }

    final title = overrideTitle ?? 'Si è verificato un errore';
    final message = overrideMessage ??
        (error is Exception || error is Error
            ? error.toString().replaceFirst(RegExp('^Exception: '), '').trim()
            : 'Qualcosa è andato storto. Riprova più tardi.');

    return _ParsedBackendError(
      title: title,
      message: message.isEmpty
          ? 'Qualcosa è andato storto. Riprova più tardi.'
          : message,
      icon: Icons.error_outline,
      iconColor: theme.colorScheme.error,
      iconBackground: theme.colorScheme.error.withOpacity(0.08),
    );
  }

  static String _titleForStatus(int? status) {
    switch (status) {
      case 400:
        return 'Richiesta non valida';
      case 401:
        return 'Autenticazione richiesta';
      case 403:
        return 'Operazione non consentita';
      case 404:
        return 'Risorsa non trovata';
      case 409:
        return 'Conflitto rilevato';
      case 422:
        return 'Dati non validi';
      case 500:
        return 'Errore del server';
      default:
        if (status != null && status >= 500) {
          return 'Errore del server';
        }
        return 'Si è verificato un errore';
    }
  }

  static String _defaultMessageForStatus(int? status) {
    switch (status) {
      case 400:
        return 'Controlla i dati inseriti e riprova.';
      case 401:
        return 'Effettua nuovamente l\'accesso per continuare.';
      case 403:
        return 'Non hai i permessi necessari per completare questa azione.';
      case 404:
        return 'Non è stato possibile trovare la risorsa richiesta.';
      case 409:
        return 'Esiste già un elemento in conflitto con questa operazione.';
      case 422:
        return 'Alcuni dati non sono validi. Controlla gli errori e riprova.';
      default:
        if (status != null && status >= 500) {
          return 'Il server ha riscontrato un problema. Riprova più tardi.';
        }
        return 'Qualcosa è andato storto. Riprova più tardi.';
    }
  }

  static IconData _iconForStatus(int? status) {
    switch (status) {
      case 400:
      case 409:
      case 422:
        return Icons.warning_amber_outlined;
      case 401:
      case 403:
        return Icons.lock_outline;
      case 404:
        return Icons.search_off_outlined;
      default:
        if (status != null && status >= 500) {
          return Icons.cloud_off;
        }
        return Icons.error_outline;
    }
  }

  static (Color?, Color?) _iconColorsForStatus(ThemeData theme, int? status) {
    if (status != null && status >= 500) {
      return (
        theme.colorScheme.error,
        theme.colorScheme.error.withOpacity(0.08),
      );
    }
    if (status == 401 || status == 403) {
      final color = theme.colorScheme.secondary;
      return (color, color.withOpacity(0.12));
    }
    if (status == 404) {
      final color = theme.colorScheme.outline;
      return (color, color.withOpacity(0.12));
    }
    if (status == 400 || status == 409 || status == 422) {
      final color = theme.colorScheme.tertiary;
      return (color, color.withOpacity(0.12));
    }
    final color = theme.colorScheme.primary;
    return (color, color.withOpacity(0.12));
  }

  static String? _messageFromResponse(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data == null) {
      return error.message;
    }

    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      final message = data['message'];
      final errorDescription = data['error'];
      final fallback = data['description'];

      String? fromField(dynamic field) {
        if (field is String && field.trim().isNotEmpty) return field;
        if (field is List && field.isNotEmpty) {
          final first = field.first;
          if (first is String && first.trim().isNotEmpty) return first;
          if (first is Map && first['msg'] is String) {
            return (first['msg'] as String).trim();
          }
        }
        if (field is Map && field['message'] is String) {
          return (field['message'] as String).trim();
        }
        return null;
      }

      return fromField(detail) ??
          fromField(message) ??
          fromField(errorDescription) ??
          fromField(fallback) ??
          error.message;
    }

    if (data is List) {
      if (data.isEmpty) return error.message;
      final first = data.first;
      if (first is String && first.trim().isNotEmpty) {
        return first;
      }
      if (first is Map && first['msg'] is String) {
        return (first['msg'] as String).trim();
      }
    }

    return error.message;
  }
}
