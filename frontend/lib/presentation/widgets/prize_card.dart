import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class PrizeCard extends StatelessWidget {
  const PrizeCard({super.key, required this.prize, this.onTap, this.onDelete});
  final Prize prize;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.of(context).size.width;
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : mediaWidth;
        final maxWidth = _responsiveCardWidth(availableWidth);
        final cardWidth = math.min(availableWidth, maxWidth);

        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : cardWidth / 0.62;
        final desiredImageHeight = cardWidth / (16 / 9);
        final imageHeight = math.max(
          90.0,
          math.min(desiredImageHeight, maxHeight * 0.45),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: InkWell(
              onTap: onTap ??
                  () => context.push(AppRoute.prizeDetails(prize.prizeId),
                      extra: prize),
              borderRadius: BorderRadius.circular(16),
              splashColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prize.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prize.sponsor,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(
                              label: Text(
                                  'EUR ${(prize.valueCents / 100).toStringAsFixed(2)}'),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(
                                AppRoute.createPoolForPrize(prize.prizeId),
                                extra: prize,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Crea pool'),
                            ),
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: onDelete,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Elimina'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _responsiveCardWidth(double availableWidth) {
  if (availableWidth >= 1200) return 780;
  if (availableWidth >= 992) return 720;
  if (availableWidth >= 768) return 640;
  return availableWidth;
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
