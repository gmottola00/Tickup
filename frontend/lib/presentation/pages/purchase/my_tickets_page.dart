import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/purchase/purchase_provider.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';

class MyTicketsPage extends ConsumerWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participatingPools = ref.watch(myParticipatingPoolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei ticket'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myParticipatingPoolsProvider);
          ref.invalidate(myPurchasesProvider);
          await ref.read(myParticipatingPoolsProvider.future);
        },
        child: participatingPools.when(
          loading: () => const _MyTicketsLoading(),
          error: (error, _) => _MyTicketsError(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(myParticipatingPoolsProvider);
            },
          ),
          data: (pools) => _MyTicketsContent(pools: pools),
        ),
      ),
    );
  }
}

class _MyTicketsLoading extends StatelessWidget {
  const _MyTicketsLoading();

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
        final childAspectRatio = width >= 600 ? 3 / 5 : 2 / 3;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const PoolCardSkeleton(),
        );
      },
    );
  }
}

class _MyTicketsError extends StatelessWidget {
  const _MyTicketsError({required this.error, required this.onRetry});

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
          ),
        ],
      ),
    );
  }
}

class _MyTicketsContent extends StatelessWidget {
  const _MyTicketsContent({required this.pools});

  final List<RafflePool> pools;

  @override
  Widget build(BuildContext context) {
    if (pools.isEmpty) {
      return const _MyTicketsEmpty();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 600
                ? 3
                : 2;
        final childAspectRatio = width >= 600 ? 3 / 5 : 2 / 3;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: pools.length,
          itemBuilder: (_, index) => PoolCard(pool: pools[index]),
        );
      },
    );
  }
}

class _MyTicketsEmpty extends StatelessWidget {
  const _MyTicketsEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Non hai ancora acquistato ticket',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Partecipa ad un pool dalla pagina del premio',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
