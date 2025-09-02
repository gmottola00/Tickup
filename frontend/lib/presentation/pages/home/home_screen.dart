import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/data/models/prize.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prizesAsync = ref.watch(prizesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickup'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(prizesProvider);
          await ref.read(prizesProvider.future);
        },
        child: prizesAsync.when(
          loading: () => const _HomeLoading(),
          error: (e, _) => _HomeError(
              error: e.toString(),
              onRetry: () {
                ref.invalidate(prizesProvider);
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
      itemBuilder: (_, __) => const _PrizeCardSkeleton(),
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
  final List<Prize> items;

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
      itemBuilder: (_, i) => _PrizeCard(prize: items[i]),
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
          const Icon(Icons.emoji_events_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Nessun premio disponibile',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il primo premio con il pulsante +',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({required this.prize});
  final Prize prize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: prize.imageUrl.startsWith('http')
                ? Image.network(
                    prize.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  prize.sponsor,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                          '€ ${(prize.valueCents / 100).toStringAsFixed(2)}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Stock: ${prize.stock}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeCardSkeleton extends StatelessWidget {
  const _PrizeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12, width: 120, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 80, color: Colors.grey.shade300),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                          height: 24, width: 60, color: Colors.grey.shade300),
                      const SizedBox(width: 8),
                      Container(
                          height: 24, width: 80, color: Colors.grey.shade300),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
