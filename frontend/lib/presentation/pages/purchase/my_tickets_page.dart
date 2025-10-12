import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/features/purchase/purchase_provider.dart';
import 'package:tickup/presentation/pages/purchase/purchase_page_args.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/widgets/bottom_nav_bar.dart';

class MyTicketsPage extends ConsumerWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(myPoolParticipationSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pool a cui partecipo'),
      ),
      bottomNavigationBar: const ModernBottomNavigation(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPurchasesProvider);
          ref.invalidate(myParticipatingPoolsProvider);
          ref.invalidate(myPoolParticipationSummariesProvider);
          await ref.read(myPoolParticipationSummariesProvider.future);
        },
        child: summaries.when(
          loading: () => const _ParticipationsLoading(),
          error: (error, _) => _ParticipationsError(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(myPoolParticipationSummariesProvider);
            },
          ),
          data: (items) => _ParticipationsContent(summaries: items),
        ),
      ),
    );
  }
}

class _ParticipationsLoading extends StatelessWidget {
  const _ParticipationsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ParticipationsError extends StatelessWidget {
  const _ParticipationsError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

class _ParticipationsContent extends StatelessWidget {
  const _ParticipationsContent({required this.summaries});

  final List<PoolParticipationSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const _ParticipationsEmpty();
    }

    final ordered = [...summaries]
      ..sort((a, b) {
        final aDate = a.lastPurchaseAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.lastPurchaseAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) => _ParticipationCard(summary: ordered[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: ordered.length,
    );
  }
}

class _ParticipationCard extends ConsumerWidget {
  const _ParticipationCard({required this.summary});

  final PoolParticipationSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardMaxWidth = _participationCardWidth(constraints.maxWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: FutureBuilder<Prize>(
              future: ref
                  .read(prizeRepositoryProvider)
                  .fetchPrize(summary.pool.prizeId),
              builder: (context, snapshot) {
                final theme = Theme.of(context);
                final prize = snapshot.data;

                final imageUrl = prize?.imageUrl ?? '';
                final title = prize?.title ?? 'Pool';
                final subtitle = prize?.sponsor ?? '';

                final ticketPrice = summary.pool.ticketPriceCents / 100;
                final totalSpent = summary.totalAmountCents / 100;
                final lastPurchase = summary.lastPurchaseAt;

                return LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final isCompact = cardConstraints.maxWidth < 520;
                    final actionsVertical = cardConstraints.maxWidth < 480;
                    final avatarSize = isCompact ? 64.0 : 80.0;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: avatarSize,
                                  height: avatarSize,
                                  child: imageUrl.startsWith('http')
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _PlaceholderImage(title: title),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: _PlaceholderImage(title: title),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Chip(
                                            avatar: const Icon(
                                              Icons.confirmation_number_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              '${summary.ticketsCount} ticket',
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Chip(
                                            avatar: const Icon(
                                              Icons.euro,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'EUR ${totalSpent.toStringAsFixed(2)} spesi',
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Chip(
                                            avatar: const Icon(
                                              Icons.sell_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'Ticket EUR ${ticketPrice.toStringAsFixed(2)}',
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${summary.pool.ticketsSold}/${summary.pool.ticketsRequired} ticket venduti',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: summary.pool.ticketsRequired > 0
                                  ? (summary.pool.ticketsSold /
                                          summary.pool.ticketsRequired)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                            ),
                            if (lastPurchase != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Ultimo acquisto: ${_formatDate(lastPurchase)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (actionsVertical) ...[
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.push(
                                    AppRoute.poolDetails(
                                      summary.pool.poolId,
                                    ),
                                    extra: summary.pool,
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Vedi pool'),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  context.push(
                                    AppRoute.purchaseForPool(
                                      summary.pool.poolId,
                                    ),
                                    extra: PurchasePageArgs(
                                      pool: summary.pool,
                                      prize: prize,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                ),
                                label: const Text('Compra altro'),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        context.push(
                                          AppRoute.poolDetails(
                                            summary.pool.poolId,
                                          ),
                                          extra: summary.pool,
                                        );
                                      },
                                      icon:
                                          const Icon(Icons.visibility_outlined),
                                      label: const Text('Vedi pool'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        context.push(
                                          AppRoute.purchaseForPool(
                                            summary.pool.poolId,
                                          ),
                                          extra: PurchasePageArgs(
                                            pool: summary.pool,
                                            prize: prize,
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart_outlined,
                                      ),
                                      label: const Text('Compra altro'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

double _participationCardWidth(double availableWidth) {
  if (availableWidth >= 1200) return 780;
  if (availableWidth >= 992) return 720;
  if (availableWidth >= 768) return 640;
  return availableWidth;
}

class _ParticipationsEmpty extends StatelessWidget {
  const _ParticipationsEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 64),
          const SizedBox(height: 12),
          Text('Non stai partecipando a nessun pool',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Acquista un ticket per unirti a un pool disponibile',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? 'Pool' : title[0].toUpperCase(),
        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return date.toLocal().toString().split('.').first;
}
