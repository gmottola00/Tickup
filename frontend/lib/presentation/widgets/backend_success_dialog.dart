import 'dart:async';

import 'package:flutter/material.dart';

typedef BackendSuccessActionCallback = FutureOr<void> Function(
  BuildContext context,
);

/// Dialog standard per confermare il buon esito di operazioni backend.
/// Permette di personalizzare titolo, messaggio e azioni mostrate.
class BackendSuccessAction {
  BackendSuccessAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.closeOnTap = true,
  });

  final String label;
  final BackendSuccessActionCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool closeOnTap;

  factory BackendSuccessAction.dismiss({
    String label = 'Chiudi',
    IconData? icon,
    bool isPrimary = false,
  }) {
    return BackendSuccessAction(
      label: label,
      icon: icon,
      isPrimary: isPrimary,
      onPressed: (_) {},
    );
  }
}

class BackendSuccessDialog {
  const BackendSuccessDialog._();

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    List<BackendSuccessAction>? actions,
    bool barrierDismissible = true,
  }) async {
    final rootContext = context;
    final theme = Theme.of(rootContext);
    final resolvedTitle = title ?? 'Operazione completata';
    final resolvedMessage =
        message ?? 'L\'operazione è stata completata con successo.';

    final effectiveActions = (actions == null || actions.isEmpty)
        ? <BackendSuccessAction>[BackendSuccessAction.dismiss()]
        : actions;

    final iconColor = theme.colorScheme.primary;
    final iconBackground = theme.colorScheme.primary.withOpacity(0.12);

    await showDialog<void>(
      context: rootContext,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  resolvedTitle,
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
              Text(
                resolvedMessage,
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
    required BackendSuccessAction action,
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
