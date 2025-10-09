import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/widgets/responsive_card_data.dart';

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
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        
        // Calcola dimensioni responsive
        final responsiveData = calculateResponsiveCardDimensions(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          availableWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth,
          availableHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : screenHeight,
          cardType: CardType.pool,
        );

        final progress = pool.ticketsRequired > 0
            ? (pool.ticketsSold / pool.ticketsRequired).clamp(0.0, 1.0)
            : 0.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsiveData.cardWidth,
              minHeight: responsiveData.minCardHeight,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(responsiveData.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PoolCardHeader(
                        pool: pool, 
                        imageHeight: responsiveData.imageHeight,
                        titleStyle: responsiveData.titleStyle,
                      ),
                      SizedBox(height: responsiveData.spacing),
                      _PoolCardBody(
                        pool: pool,
                        progress: progress,
                        onDelete: onDelete,
                        onToggleLike: onToggleLike,
                        isLiked: isLiked,
                        textStyle: responsiveData.bodyTextStyle,
                        spacing: responsiveData.spacing,
                        buttonSize: responsiveData.buttonSize,
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
    this.textStyle,
    required this.spacing,
    required this.buttonSize,
  });

  final RafflePool pool;
  final double progress;
  final bool isLiked;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleLike;
  final TextStyle? textStyle;
  final double spacing;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ticket: EUR ${(pool.ticketPriceCents / 100).toStringAsFixed(2)}',
          style: textStyle,
        ),
        SizedBox(height: spacing * 0.6),
        LinearProgressIndicator(value: progress),
        SizedBox(height: spacing * 0.3),
        Text(
          '${pool.ticketsSold}/${pool.ticketsRequired} venduti',
          style: textStyle?.copyWith(fontSize: (textStyle?.fontSize ?? 14) * 0.9),
        ),
        SizedBox(height: spacing * 0.3),
        Text(
          '${pool.likes} mi piace',
          style: textStyle?.copyWith(fontSize: (textStyle?.fontSize ?? 14) * 0.9),
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Chip(
              label: Text(
                pool.state,
                style: TextStyle(fontSize: (textStyle?.fontSize ?? 14) * 0.8),
              ),
              visualDensity: VisualDensity.compact,
            ),
            const Spacer(),
            IconButton(
              onPressed: onToggleLike,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: buttonSize,
              ),
              color: isLiked ? theme.colorScheme.error : null,
              tooltip: isLiked ? 'Rimuovi dai preferiti' : 'Mi piace',
              constraints: BoxConstraints(
                minWidth: buttonSize + 8,
                minHeight: buttonSize + 8,
              ),
            ),
            if (onDelete != null) ...[
              SizedBox(width: spacing * 0.3),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: buttonSize),
                tooltip: 'Elimina pool',
                constraints: BoxConstraints(
                  minWidth: buttonSize + 8,
                  minHeight: buttonSize + 8,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PoolCardHeader extends ConsumerWidget {
  const _PoolCardHeader({
    required this.pool, 
    required this.imageHeight,
    this.titleStyle,
  });

  final RafflePool pool;
  final double imageHeight;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: Container(
              color: Colors.grey.shade300,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: imageHeight * 0.3,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        );

    final prizeAsync = ref.watch(prizeProvider(pool.prizeId));

    return prizeAsync.when(
      loading: () => _HeaderContent(
        image: placeholder(),
        title: 'Caricamento...',
        theme: theme,
        titleStyle: titleStyle,
      ),
      error: (_, __) => _HeaderContent(
        image: placeholder(),
        title: 'Premio non disponibile',
        theme: theme,
        titleStyle: titleStyle,
      ),
      data: (prize) {
        final url = prize.imageUrl;
        final image = buildImage(
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.isNotEmpty && url.startsWith('http')
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => placeholder(),
                  )
                : placeholder(),
          ),
        );

        return _HeaderContent(
          image: image,
          title: prize.title,
          theme: theme,
          titleStyle: titleStyle,
        );
      },
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.image, 
    required this.title, 
    required this.theme,
    this.titleStyle,
  });

  final Widget image;
  final String title;
  final ThemeData theme;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(height: 8),
        Text(
          title,
          style: titleStyle ?? theme.textTheme.titleMedium,
          maxLines: 2, // Permetti più righe per titoli lunghi
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class PoolCardSkeleton extends StatelessWidget {
  const PoolCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        final responsiveData = calculateResponsiveCardDimensions(
          screenWidth: screenWidth,
          screenHeight: mediaQuery.size.height,
          availableWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth,
          availableHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : mediaQuery.size.height,
          cardType: CardType.pool,
        );

        return Card(
          child: Container(
            width: responsiveData.cardWidth,
            height: responsiveData.minCardHeight,
            padding: EdgeInsets.all(responsiveData.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton per l'immagine
                Container(
                  height: responsiveData.imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: responsiveData.spacing),
                // Skeleton per il titolo
                Container(
                  height: 20,
                  width: double.infinity * 0.8,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: responsiveData.spacing),
                // Skeleton per il contenuto
                Container(
                  height: 16,
                  width: double.infinity * 0.6,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
