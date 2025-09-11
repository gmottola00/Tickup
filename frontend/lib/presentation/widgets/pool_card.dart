import 'package:flutter/material.dart';
import 'package:tickup/data/models/raffle_pool.dart';

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
                  Text(
                    '#${pool.poolId.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Chip(
                    label: Text(pool.state),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Ticket: € ${(pool.ticketPriceCents / 100).toStringAsFixed(2)}'),
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

