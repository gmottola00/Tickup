import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/pool/pool_like_provider.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/widgets/card_grid_config.dart';
import 'package:tickup/presentation/widgets/pool_card.dart';

class LikedPoolsPage extends ConsumerWidget {
  const LikedPoolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedPools = ref.watch(likedPoolsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei preferiti'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(likedPoolsProvider);
          await ref.read(likedPoolsProvider.future);
        },
        child: likedPools.when(
          loading: () => const _LikedPoolsLoading(),
          error: (e, _) => _LikedPoolsError(
            error: e.toString(),
            onRetry: () => ref.invalidate(likedPoolsProvider),
          ),
          data: (items) => _LikedPoolsContent(items: items),
        ),
      ),
    );
  }
}

class _LikedPoolsLoading extends StatelessWidget {
  const _LikedPoolsLoading();
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

class _LikedPoolsError extends StatelessWidget {
  const _LikedPoolsError({required this.error, required this.onRetry});
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

class _LikedPoolsContent extends ConsumerWidget {
  const _LikedPoolsContent({required this.items});
  final List<RafflePool> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _LikedPoolsEmpty();
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
            final effective = like != null
                ? pool.copyWith(likes: like.likes, likedByMe: like.likedByMe)
                : pool;
            return PoolCard(
              pool: effective,
              isLiked: like?.likedByMe ?? pool.likedByMe,
              onToggleLike: () async {
                await ref.read(poolLikeProvider(pool.poolId).notifier).toggle();
                // Refresh the whole list in case item moved out
                ref.invalidate(likedPoolsProvider);
              },
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

class _LikedPoolsEmpty extends StatelessWidget {
  const _LikedPoolsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64),
          const SizedBox(height: 12),
          Text(
            'Nessun preferito',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tocca il cuore su un pool per aggiungerlo ai preferiti',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
