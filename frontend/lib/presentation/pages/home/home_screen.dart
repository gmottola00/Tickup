import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolsAsync = ref.watch(poolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickup'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(poolsProvider);
          await ref.read(poolsProvider.future);
        },
        child: poolsAsync.when(
          loading: () => const _HomeLoading(),
          error: (e, _) => _HomeError(
              error: e.toString(),
              onRetry: () {
                ref.invalidate(poolsProvider);
              }),
          data: (items) => _HomeContent(items: items),
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const PoolCardSkeleton(),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.items});
  final List<RafflePool> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState();
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PoolCard(pool: items[i]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Nessun pool disponibile',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un pool per iniziare a vendere ticket',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Card UI moved to reusable widget in presentation/widgets/pool_card.dart
