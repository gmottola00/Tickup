import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/prize_image.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/repositories/raffle_repository.dart';
import 'package:tickup/presentation/features/prize/prize_images_provider.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/pages/purchase/purchase_page_args.dart';
import 'package:tickup/presentation/routing/app_route.dart';

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

class _PoolDetailsView extends ConsumerWidget {
  const _PoolDetailsView({
    required this.pool,
    required this.prize,
    required this.relatedPools,
  });

  final RafflePool pool;
  final Prize prize;
  final List<RafflePool> relatedPools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priceEur = (prize.valueCents / 100).toStringAsFixed(2);
    final ticketEur = (pool.ticketPriceCents / 100).toStringAsFixed(2);
    final progress = pool.ticketsRequired > 0
        ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
        : 0.0;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == prize.userId;

    final imagesAsync = ref.watch(prizeImagesProvider(prize.prizeId));
    final gallery = _resolvePrizeGallery(imagesAsync.valueOrNull ?? const <PrizeImage>[], prize.imageUrl);
    final coverUrl = gallery.coverUrl;
    final galleryUrls = gallery.galleryUrls;
    final initialIndex = coverUrl != null ? galleryUrls.indexOf(coverUrl) : 0;
    final resolvedInitialIndex = (galleryUrls.isEmpty || initialIndex < 0)
        ? 0
        : (initialIndex.clamp(0, galleryUrls.length - 1) as num).toInt();

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
              background: GestureDetector(
                onTap: galleryUrls.isEmpty
                    ? null
                    : () => _showPrizeGallery(
                          context,
                          galleryUrls,
                          initialPage: resolvedInitialIndex,
                        ),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PrizeHeaderImage(
                      url: coverUrl,
                      placeholderIcon: Icons.image,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.45),
                          ],
                        ),
                      ),
                    ),
                    if (galleryUrls.isNotEmpty)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${galleryUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.confirmation_number,
                            label: 'Ticket',
                            value: '€ $ticketEur',
                          ),
                        ),
                        const _MetricDivider(),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.flag_outlined,
                            label: 'Stato',
                            value: pool.state,
                          ),
                        ),
                        const _MetricDivider(),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock',
                            value: '${prize.stock}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Avanzamento',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '${pool.ticketsSold}/${pool.ticketsRequired} ticket',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: theme.colorScheme.surface,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Restano ${pool.ticketsRequired - pool.ticketsSold} ticket per completare il pool.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (prize.sponsor.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            Icons.business,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: const Text('Sponsor'),
                        subtitle: Text(prize.sponsor),
                      ),
                    ),
                  if (prize.sponsor.isNotEmpty) const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descrizione premio', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Text(
                            prize.description.isNotEmpty
                                ? prize.description
                                : 'Nessuna descrizione disponibile.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (relatedPools.isNotEmpty)
                    _PoolSummaryCard(
                      pool: relatedPools.first,
                      isOwner: isOwner,
                    ),
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

class _PoolSummaryCard extends StatelessWidget {
  const _PoolSummaryCard({required this.pool, required this.isOwner});

  final RafflePool pool;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticketEur = (pool.ticketPriceCents / 100).toStringAsFixed(2);
    final progress = pool.ticketsRequired > 0
        ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
        : 0.0;

    final remaining = (pool.ticketsRequired - pool.ticketsSold).clamp(0, pool.ticketsRequired);

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.primary.withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: theme.colorScheme.primary.withOpacity(0.25),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.25),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pool attivo',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Creato da te',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniMetricChip(
                icon: Icons.flag_outlined,
                label: pool.state,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              _MiniMetricChip(
                icon: Icons.euro,
                label: '€ $ticketEur',
                color: theme.colorScheme.onPrimaryContainer,
              ),
              _MiniMetricChip(
                icon: Icons.confirmation_number,
                label: '${pool.ticketsSold}/${pool.ticketsRequired} ticket',
                color: theme.colorScheme.onPrimaryContainer,
              ),
              _MiniMetricChip(
                icon: Icons.timer_outlined,
                label: remaining > 0 ? 'Restano $remaining' : 'Completato',
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(
                theme.colorScheme.onPrimaryContainer,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white.withOpacity(0.25),
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  const _MiniMetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final background = color.withOpacity(color == Colors.white ? 0.2 : 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrizeHeaderImage extends StatelessWidget {
  const _PrizeHeaderImage({
    required this.url,
    required this.placeholderIcon,
  });

  final String? url;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            placeholderIcon,
            size: 64,
            color: Colors.grey[400],
          ),
        );

    if (url == null || url!.isEmpty) {
      return placeholder();
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}

String? _prizeImageUrl(PrizeImage image) {
  if (image.url.isNotEmpty && image.url.startsWith('http')) {
    return image.url;
  }
  if (image.bucket.isNotEmpty && image.storagePath.isNotEmpty) {
    return Supabase.instance.client.storage
        .from(image.bucket)
        .getPublicUrl(image.storagePath);
  }
  return null;
}

class _ResolvedPrizeImage {
  const _ResolvedPrizeImage({
    required this.url,
    required this.isCover,
    required this.order,
  });

  final String url;
  final bool isCover;
  final int order;
}

({String? coverUrl, List<String> galleryUrls}) _resolvePrizeGallery(
  List<PrizeImage> images,
  String fallbackUrl,
) {
  const defaultOrder = 1 << 20;
  final resolved = <_ResolvedPrizeImage>[];

  for (final image in images) {
    final url = _prizeImageUrl(image);
    if (url == null || url.isEmpty) continue;
    resolved.add(
      _ResolvedPrizeImage(
        url: url,
        isCover: image.isCover,
        order: image.sortOrder ?? defaultOrder,
      ),
    );
  }

  final hasCover = resolved.any((element) => element.isCover);
  if (fallbackUrl.isNotEmpty) {
    resolved.add(
      _ResolvedPrizeImage(
        url: fallbackUrl,
        isCover: !hasCover,
        order: hasCover ? defaultOrder + 1 : -1,
      ),
    );
  }

  final deduped = <String, _ResolvedPrizeImage>{};
  for (final entry in resolved) {
    final existing = deduped[entry.url];
    if (existing == null ||
        entry.order < existing.order ||
        (entry.isCover && !existing.isCover)) {
      deduped[entry.url] = entry;
    }
  }

  final ordered = deduped.values.toList()
    ..sort((a, b) => a.order.compareTo(b.order));

  String? coverUrl;
  for (final entry in ordered) {
    if (entry.isCover) {
      coverUrl = entry.url;
      break;
    }
  }
  coverUrl ??= ordered.isNotEmpty ? ordered.first.url : null;

  return (
    coverUrl: coverUrl,
    galleryUrls: ordered.map((e) => e.url).toList(),
  );
}

Future<void> _showPrizeGallery(
  BuildContext context,
  List<String> urls, {
  required int initialPage,
}) async {
  if (urls.isEmpty) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => _PrizeImageGalleryDialog(
      urls: urls,
      initialIndex: initialPage,
    ),
  );
}

class _PrizeImageGalleryDialog extends StatefulWidget {
  const _PrizeImageGalleryDialog({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_PrizeImageGalleryDialog> createState() => _PrizeImageGalleryDialogState();
}

class _PrizeImageGalleryDialogState extends State<_PrizeImageGalleryDialog> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    final clampedIndex = widget.urls.isEmpty
        ? 0
        : (widget.initialIndex.clamp(0, widget.urls.length - 1) as num).toInt();
    _current = clampedIndex;
    _controller = PageController(initialPage: clampedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.urls.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) {
                  final url = widget.urls[index];
                  return InteractiveViewer(
                    maxScale: 4,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 72,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_current + 1} / ${widget.urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
