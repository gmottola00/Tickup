import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/widgets/prize_card.dart';
import 'package:tickup/presentation/widgets/card_grid_config.dart';
import 'package:tickup/presentation/widgets/backend_error_dialog.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/widgets/bottom_nav_bar.dart';

class MyPrizesPage extends ConsumerWidget {
  const MyPrizesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPrizes = ref.watch(myPrizesProvider);

    return Scaffold(
      extendBody: true,
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
      bottomNavigationBar: const ModernBottomNavigation(),
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
        final grid = defaultCardGridConfig(width);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: grid.childAspectRatio,
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
        final grid = defaultCardGridConfig(width);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: grid.crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: grid.childAspectRatio,
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
          'Confermi l\'eliminazione del premio "${prize.title}"? Questa azione non Ã¨ reversibile.',
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

    try {
      await ref.read(prizeRepositoryProvider).deletePrize(prize.prizeId);
      ref.invalidate(myPrizesProvider);
      ref.invalidate(prizesProvider);
      ref.invalidate(myPoolsProvider);
      ref.invalidate(poolsProvider);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Premio eliminato con successo.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      await BackendErrorDialog.show(
        context,
        error: error,
        title: 'Eliminazione non completata',
        actions: _buildDeleteErrorActions(context, ref, prize),
      );
    }
  }

  List<BackendErrorAction> _buildDeleteErrorActions(
    BuildContext context,
    WidgetRef ref,
    Prize prize,
  ) {
    final actions = <BackendErrorAction>[];
    final poolId = _findAssociatedPoolId(ref, prize.prizeId);

    if (poolId != null) {
      actions.add(
        BackendErrorAction(
          label: 'Apri pool collegato',
          icon: Icons.confirmation_number_outlined,
          isPrimary: true,
          onPressed: (ctx) {
            GoRouter.of(ctx).push(
              AppRoute.poolDetails(poolId),
            );
          },
        ),
      );
    }

    actions.add(BackendErrorAction.dismiss(icon: Icons.close));
    return actions;
  }

  String? _findAssociatedPoolId(WidgetRef ref, String prizeId) {
    final candidates = [
      ref.read(myPoolsProvider),
      ref.read(poolsProvider),
    ];

    for (final asyncPools in candidates) {
      final poolId = asyncPools.maybeWhen(
        data: (pools) => _poolIdForPrize(pools, prizeId),
        orElse: () => null,
      );
      if (poolId != null) return poolId;
    }

    return null;
  }

  String? _poolIdForPrize(List<RafflePool> pools, String prizeId) {
    for (final pool in pools) {
      if (pool.prizeId == prizeId) {
        return pool.poolId;
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
