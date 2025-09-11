import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/widgets/prize_card.dart';
import 'package:tickup/data/models/prize.dart';

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
        final childAspectRatio = width >= 600 ? 3 / 5 : 2 / 3; // più verticale
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

class _MyPrizesContent extends StatelessWidget {
  const _MyPrizesContent({required this.items});
  final List<Prize> items;

  @override
  Widget build(BuildContext context) {
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
          itemBuilder: (_, i) => PrizeCard(prize: items[i]),
        );
      },
    );
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
