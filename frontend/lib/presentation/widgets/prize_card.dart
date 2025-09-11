import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class PrizeCard extends StatelessWidget {
  const PrizeCard({super.key, required this.prize, this.onTap});
  final Prize prize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? () => context.push(AppRoute.prizeDetails(prize.prizeId), extra: prize),
      borderRadius: BorderRadius.circular(16),
      splashColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Card(
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
                        label: Text('€ ${(prize.valueCents / 100).toStringAsFixed(2)}'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                          AppRoute.createPoolForPrize(prize.prizeId),
                          extra: prize,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Crea pool'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrizeCardSkeleton extends StatelessWidget {
  const PrizeCardSkeleton({super.key});

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 80, color: Colors.grey.shade300),
                  const Spacer(),
                  Row(
                    children: [
                      Container(height: 24, width: 60, color: Colors.grey.shade300),
                      const SizedBox(width: 8),
                      Container(height: 24, width: 80, color: Colors.grey.shade300),
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
