import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';
import 'package:tickup/presentation/features/pool/pool_like_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/widgets/card_grid_config.dart';

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
            },
          ),
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
          itemBuilder: (_, __) => const PoolCardSkeleton(),
        );
      },
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

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.items});
  final List<RafflePool> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState();
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
          itemBuilder: (_, i) {
            final pool = items[i];
            final like = ref.watch(poolLikeProvider(pool.poolId));
            final effectivePool = like != null
                ? pool.copyWith(likes: like.likes, likedByMe: like.likedByMe)
                : pool;
            return PoolCard(
              pool: effectivePool,
              isLiked: like?.likedByMe ?? pool.likedByMe,
              onToggleLike: () => ref.read(poolLikeProvider(pool.poolId).notifier).toggle(),
              onTap: () => context.push(
                AppRoute.poolDetails(pool.poolId),
                extra: pool,
              ),
            );
          },
        );
      },
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
