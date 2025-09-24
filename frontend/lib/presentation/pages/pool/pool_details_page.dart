import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/repositories/raffle_repository.dart';
import 'package:tickup/presentation/pages/purchase/purchase_page_args.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';

class PoolDetailsPage extends ConsumerWidget {
  const PoolDetailsPage({super.key, required this.poolId, this.initial});

  final String poolId;
  final RafflePool? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initial != null) {
      return _PoolDetailsLoader(initial: initial!);
    }
    return FutureBuilder<RafflePool>(
      future: RaffleRepository().fetchPool(poolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Errore: ${snapshot.error}')),
          );
        }
        return _PoolDetailsLoader(initial: snapshot.data!);
      },
    );
  }
}

class _PoolDetailsLoader extends ConsumerWidget {
  const _PoolDetailsLoader({required this.initial});
  final RafflePool initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Prize>(
      future: ref.read(prizeRepositoryProvider).fetchPrize(initial.prizeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Errore: ${snapshot.error}')),
          );
        }
        return FutureBuilder<List<RafflePool>>(
          future: RaffleRepository().fetchPools(),
          builder: (context, poolsSnapshot) {
            if (poolsSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (poolsSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text('Errore: ${poolsSnapshot.error}')),
              );
            }

            final allPools = poolsSnapshot.data ?? const <RafflePool>[];
            final relatedMap = {
              for (final pool in allPools
                  .where((pool) => pool.prizeId == initial.prizeId))
                pool.poolId: pool,
            };
            relatedMap[initial.poolId] = initial;

            final relatedPools = relatedMap.values.toList()
              ..sort((a, b) {
                final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

            return _PoolDetailsView(
              pool: initial,
              prize: snapshot.data!,
              relatedPools: relatedPools,
            );
          },
        );
      },
    );
  }
}

class _PoolDetailsView extends StatelessWidget {
  const _PoolDetailsView({
    required this.pool,
    required this.prize,
    required this.relatedPools,
  });

  final RafflePool pool;
  final Prize prize;
  final List<RafflePool> relatedPools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceEur = (prize.valueCents / 100).toStringAsFixed(2);
    final ticketEur = (pool.ticketPriceCents / 100).toStringAsFixed(2);
    final progress = pool.ticketsRequired > 0
        ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
        : 0.0;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == prize.userId;

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
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pool info
                  Row(
                    children: [
                      Chip(
                        label: Text('Ticket: € $ticketEur'),
                        avatar: const Icon(Icons.confirmation_number, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Stato: ${pool.state}'),
                        avatar: const Icon(Icons.flag, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text('${pool.ticketsSold}/${pool.ticketsRequired} venduti'),

                  const SizedBox(height: 24),
                  // Prize info
                  Row(
                    children: [
                      Chip(
                        label: Text('Valore: € $priceEur'),
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
                  Text('Descrizione premio', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(prize.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  if (pool.createdAt != null)
                    Text(
                      'Creato il: ${pool.createdAt!.toLocal().toString().split('.').first}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (relatedPools.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Pool collegati a questo premio',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      itemCount: relatedPools.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final related = relatedPools[index];
                        return Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                          child: _RelatedPoolCard(
                            pool: related,
                            isCurrent: related.poolId == pool.poolId,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(
                      AppRoute.purchaseForPool(pool.poolId),
                      extra: PurchasePageArgs(pool: pool, prize: prize),
                    );
                  },
                  child: const Text('Entra'),
                ),
              ),
            ),
    );
  }
}

class _RelatedPoolCard extends StatelessWidget {
  const _RelatedPoolCard({required this.pool, required this.isCurrent});

  final RafflePool pool;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticketEur = (pool.ticketPriceCents / 100).toStringAsFixed(2);
    final progress = pool.ticketsRequired > 0
        ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
        : 0.0;

    final cardColor = isCurrent ? theme.colorScheme.primaryContainer : null;
    final textColor = isCurrent
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCurrent) ...[
              Text(
                'Pool corrente',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _InfoRow(
              label: 'Pool ID',
              value: pool.poolId,
              textColor: textColor,
            ),
            _InfoRow(
              label: 'Stato',
              value: pool.state,
              textColor: textColor,
            ),
            _InfoRow(
              label: 'Prezzo ticket (EUR)',
              value: '€ $ticketEur',
              textColor: textColor,
            ),
            _InfoRow(
              label: 'Ticket richiesti',
              value: pool.ticketsRequired.toString(),
              textColor: textColor,
            ),
            _InfoRow(
              label: 'Ticket venduti',
              value: pool.ticketsSold.toString(),
              textColor: textColor,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '${pool.ticketsSold}/${pool.ticketsRequired} venduti',
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
            if (pool.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Creato il: ${pool.createdAt!.toLocal().toString().split('.').first}',
                style: theme.textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.textColor});

  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
