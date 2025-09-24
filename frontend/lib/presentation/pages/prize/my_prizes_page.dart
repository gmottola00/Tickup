import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/widgets/prize_card.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';

class MyPrizesPage extends ConsumerWidget {
  const MyPrizesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPrizes = ref.watch(myPrizesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei oggetti'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPrizesProvider);
          await ref.read(myPrizesProvider.future);
        },
        child: myPrizes.when(
          loading: () => const _MyPrizesLoading(),
          error: (e, _) => _MyPrizesError(
            error: e.toString(),
            onRetry: () => ref.invalidate(myPrizesProvider),
          ),
          data: (items) => _MyPrizesContent(items: items),
        ),
      ),
    );
  }
}

class _MyPrizesLoading extends StatelessWidget {
  const _MyPrizesLoading();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 600
                ? 3
                : 2;
        final childAspectRatio = width >= 900
            ? 0.58
            : width >= 600
                ? 0.56
                : 0.52; // più verticale
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const PrizeCardSkeleton(),
        );
      },
    );
  }
}

class _MyPrizesError extends StatelessWidget {
  const _MyPrizesError({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text('Errore: $error'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          )
        ],
      ),
    );
  }
}

class _MyPrizesContent extends ConsumerWidget {
  const _MyPrizesContent({required this.items});
  final List<Prize> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _MyPrizesEmpty();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 600
                ? 3
                : 2;
        final childAspectRatio = width >= 600 ? 3 / 5 : 2 / 3; // più verticale
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => PrizeCard(
            prize: items[i],
            onDelete: () => _confirmDelete(context, ref, items[i]),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Prize prize,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina premio'),
        content: Text(
          'Confermi l\'eliminazione del premio "${prize.title}"? Questa azione non è reversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(prizeRepositoryProvider).deletePrize(prize.prizeId);
      ref.invalidate(myPrizesProvider);
      ref.invalidate(prizesProvider);
      ref.invalidate(myPoolsProvider);
      ref.invalidate(poolsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Premio eliminato con successo.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_deleteErrorMessage(error))),
      );
    }
  }

  String _deleteErrorMessage(Object error) {
    final message = _extractErrorMessage(error);
    if (message.toLowerCase().contains('pool') ||
        message.toLowerCase().contains('raffle')) {
      return 'Impossibile eliminare il premio: rimuovi prima i pool associati.';
    }
    return message;
  }

  String _extractErrorMessage(Object error) {
    String? message;
    if (error is DioException) {
      message = _detailFromResponse(error.response?.data) ?? error.message;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is Error) {
      message = error.toString();
    }
    final cleaned = message?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return 'Errore durante l\'eliminazione del premio.';
    }
    return cleaned.replaceFirst(RegExp('^Exception: '), '').trim();
  }

  String? _detailFromResponse(Object? data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
    }
    return null;
  }
}

class _MyPrizesEmpty extends StatelessWidget {
  const _MyPrizesEmpty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Non hai ancora creato premi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un premio dalla pagina Gestione Premio',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
