import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';

class PoolCard extends StatelessWidget {
  const PoolCard({
    super.key,
    required this.pool,
    this.onTap,
    this.onDelete,
    this.onToggleLike,
    this.isLiked = false,
  });

  final RafflePool pool;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleLike;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.of(context).size.width;
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : mediaWidth;
        final maxWidth = _responsiveCardWidth(availableWidth);
        final cardWidth = math.min(availableWidth, maxWidth);

        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : cardWidth / 0.68;
        final desiredImageHeight = cardWidth / (16 / 9);
        final imageHeight = math.max(
          80.0,
          math.min(desiredImageHeight, maxHeight * 0.42),
        );
        final progress = pool.ticketsRequired > 0
            ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
            : 0.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PoolCardHeader(pool: pool, imageHeight: imageHeight),
                      const SizedBox(height: 12),
                      _PoolCardBody(
                        pool: pool,
                        progress: progress,
                        onDelete: onDelete,
                        onToggleLike: onToggleLike,
                        isLiked: isLiked,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PoolCardBody extends StatelessWidget {
  const _PoolCardBody({
    required this.pool,
    required this.progress,
    required this.isLiked,
    this.onDelete,
    this.onToggleLike,
  });

  final RafflePool pool;
  final double progress;
  final bool isLiked;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ticket: EUR ${(pool.ticketPriceCents / 100).toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text('${pool.ticketsSold}/${pool.ticketsRequired} venduti'),
        const SizedBox(height: 4),
        Text('${pool.likes} mi piace'),
        const SizedBox(height: 12),
        Row(
          children: [
            Chip(
              label: Text(pool.state),
              visualDensity: VisualDensity.compact,
            ),
            const Spacer(),
            IconButton(
              onPressed: onToggleLike,
              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
              color: isLiked ? theme.colorScheme.error : null,
              tooltip: isLiked ? 'Rimuovi dai preferiti' : 'Mi piace',
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Elimina pool',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PoolCardHeader extends ConsumerWidget {
  const _PoolCardHeader({required this.pool, required this.imageHeight});

  final RafflePool pool;
  final double imageHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Prize>(
      future: ref.read(prizeRepositoryProvider).fetchPrize(pool.prizeId),
      builder: (context, snapshot) {
        final theme = Theme.of(context);

        Widget buildImage(Widget child) {
          return SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: child,
          );
        }

        Widget placeholder() => buildImage(
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(color: Colors.grey.shade300),
              ),
            );

        if (snapshot.connectionState != ConnectionState.done) {
          return _HeaderContent(
            image: placeholder(),
            title: 'Premio',
            theme: theme,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _HeaderContent(
            image: placeholder(),
            title: 'Premio',
            theme: theme,
          );
        }

        final prize = snapshot.data!;
        final url = prize.imageUrl;
        final image = buildImage(
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.isNotEmpty && url.startsWith('http')
                ? Image.network(url, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300),
          ),
        );

        return _HeaderContent(
          image: image,
          title: prize.title,
          theme: theme,
        );
      },
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent(
      {required this.image, required this.title, required this.theme});

  final Widget image;
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

double _responsiveCardWidth(double availableWidth) {
  if (availableWidth >= 1200) return 780;
  if (availableWidth >= 992) return 720;
  if (availableWidth >= 768) return 640;
  return availableWidth;
}

class PoolCardSkeleton extends StatelessWidget {
  const PoolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(child: SizedBox.expand());
  }
}