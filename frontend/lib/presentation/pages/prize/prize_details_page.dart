import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';

class PrizeDetailsPage extends ConsumerWidget {
  const PrizeDetailsPage({super.key, required this.prizeId, this.initial});

  final String prizeId;
  final Prize? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initial != null) {
      return _PrizeDetailsView(prize: initial!);
    }
    return FutureBuilder<Prize>(
      future: ref.read(prizeRepositoryProvider).fetchPrize(prizeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Errore: ${snapshot.error}')),
          );
        }
        return _PrizeDetailsView(prize: snapshot.data!);
      },
    );
  }
}

class _PrizeDetailsView extends StatelessWidget {
  const _PrizeDetailsView({required this.prize});
  final Prize prize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceEur = (prize.valueCents / 100).toStringAsFixed(2);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                prize.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  prize.imageUrl.startsWith('http')
                      ? Image.network(
                          prize.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: const Icon(Icons.image, size: 48),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text('€ $priceEur'),
                        avatar: const Icon(Icons.euro, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Stock: ${prize.stock}'),
                        avatar: const Icon(Icons.inventory_2, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (prize.sponsor.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.business, size: 18),
                        const SizedBox(width: 6),
                        Text(prize.sponsor, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text('Descrizione', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(prize.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  if (prize.createdAt != null)
                    Text(
                      'Creato il: ${prize.createdAt!.toLocal().toString().split('.').first}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
