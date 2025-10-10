import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/presentation/features/purchase/purchase_provider.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';
import 'package:tickup/presentation/widgets/card_grid_config.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/raffle_pool.dart';

class MyPoolsPage extends ConsumerWidget {
  const MyPoolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPools = ref.watch(myPoolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei pool'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPoolsProvider);
          await ref.read(myPoolsProvider.future);
        },
        child: myPools.when(
          loading: () => const _MyPoolsLoading(),
          error: (e, _) => _MyPoolsError(
            error: e.toString(),
            onRetry: () => ref.invalidate(myPoolsProvider),
          ),
          data: (items) => _MyPoolsContent(items: items),
        ),
      ),
    );
  }
}

class _MyPoolsLoading extends StatelessWidget {
  const _MyPoolsLoading();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final grid = defaultCardGridConfig(width);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            childAspectRatio: grid.childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const PoolCardSkeleton(),
        );
      },
    );
  }
}

class _MyPoolsError extends StatelessWidget {
  const _MyPoolsError({required this.error, required this.onRetry});
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

class _MyPoolsContent extends ConsumerWidget {
  const _MyPoolsContent({required this.items});
  final List<RafflePool> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _MyPoolsEmpty();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final grid = defaultCardGridConfig(width);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            childAspectRatio: grid.childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => PoolCard(
            pool: items[i],
            showLikeButton: false,
            onDelete: () => _confirmDelete(context, ref, items[i]),
            onTap: () => context.push(
              AppRoute.poolDetails(items[i].poolId),
              extra: items[i],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RafflePool pool,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina pool'),
        content: Text(
          'Sei sicuro di voler eliminare il pool con ID ${pool.poolId}? L\'operazione Ã¨ definitiva.',
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
      await ref.read(raffleRepositoryProvider).deletePool(pool.poolId);
      ref.invalidate(myPoolsProvider);
      ref.invalidate(poolsProvider);
      ref.invalidate(myParticipatingPoolsProvider);
      ref.invalidate(myPoolParticipationSummariesProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pool eliminato con successo.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_deleteErrorMessage(error))),
      );
    }
  }

  String _deleteErrorMessage(Object error) {
    final message = _extractErrorMessage(error);
    if (message.toLowerCase().contains('integrity') ||
        message.toLowerCase().contains('constraint')) {
      return 'Impossibile eliminare il pool: verifica che non ci siano ticket o operazioni collegate.';
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
      return 'Errore durante l\'eliminazione del pool.';
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

class _MyPoolsEmpty extends StatelessWidget {
  const _MyPoolsEmpty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Non hai ancora creato pool',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un pool dalla pagina di un premio',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


