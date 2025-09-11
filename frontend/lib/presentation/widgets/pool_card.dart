import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/data/models/prize.dart';

class PoolCard extends StatelessWidget {
  const PoolCard({super.key, required this.pool, this.onTap});
  final RafflePool pool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = pool.ticketsRequired > 0
        ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
        : 0.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(pool.state),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Prize image + title
              Consumer(
                builder: (context, ref, _) {
                  return FutureBuilder<Prize>(
                    future: ref
                        .read(prizeRepositoryProvider)
                        .fetchPrize(pool.prizeId),
                    builder: (context, snapshot) {
                      final theme = Theme.of(context);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 8),
                            Text('Premio', style: theme.textTheme.titleMedium),
                          ],
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 8),
                            Text('Premio', style: theme.textTheme.titleMedium),
                          ],
                        );
                      }
                      final Prize prize = snapshot.data!;
                      final url = prize.imageUrl;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: (url.isNotEmpty && url.startsWith('http'))
                                  ? Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prize.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                  'Ticket: € ${(pool.ticketPriceCents / 100).toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text('${pool.ticketsSold}/${pool.ticketsRequired} venduti'),
            ],
          ),
        ),
      ),
    );
  }
}

class PoolCardSkeleton extends StatelessWidget {
  const PoolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(child: SizedBox.expand());
  }
}
