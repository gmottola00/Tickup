import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';
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

class _MyPoolsContent extends StatelessWidget {
  const _MyPoolsContent({required this.items});
  final List<RafflePool> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _MyPoolsEmpty();
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
          itemCount: items.length,
          itemBuilder: (_, i) => PoolCard(pool: items[i]),
        );
      },
    );
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

