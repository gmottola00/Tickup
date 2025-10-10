import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/prize_image.dart';
import 'package:tickup/presentation/features/prize/prize_images_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/widgets/responsive_card_data.dart';

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
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        
        // Calcola dimensioni responsive
        final responsiveData = calculateResponsiveCardDimensions(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          availableWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth,
          availableHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : screenHeight,
          cardType: CardType.prize,
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsiveData.cardWidth,
              minHeight: responsiveData.minCardHeight,
            ),
            child: InkWell(
              onTap: onTap ??
                  () => context.push(AppRoute.prizeDetails(prize.prizeId),
                      extra: prize),
              borderRadius: BorderRadius.circular(responsiveData.borderRadius),
              splashColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsiveData.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PrizeCardImage(
                      prize: prize,
                      imageHeight: responsiveData.imageHeight,
                      borderRadius: responsiveData.borderRadius,
                    ),
                    Padding(
                      padding: EdgeInsets.all(responsiveData.padding),
                      child: _PrizeCardContent(
                        prize: prize,
                        onDelete: onDelete,
                        theme: theme,
                        responsiveData: responsiveData,
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



class _PrizeCardImage extends ConsumerWidget {
  const _PrizeCardImage({
    required this.prize,
    required this.imageHeight,
    required this.borderRadius,
  });

  final Prize prize;
  final double imageHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(prizeImagesProvider(prize.prizeId));

    Widget placeholder() => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            Icons.image,
            size: imageHeight * 0.3,
            color: Colors.grey[400],
          ),
        );

    String? resolveUrl(List<PrizeImage> items) {
      PrizeImage? cover;
      for (final img in items) {
        if (cover == null) {
          cover = img;
        }
        if (img.isCover == true) {
          if (cover.isCover != true) {
            cover = img;
            continue;
          }
          final currentOrder = cover.sortOrder ?? (1 << 20);
          final candidateOrder = img.sortOrder ?? (1 << 20);
          if (candidateOrder < currentOrder) {
            cover = img;
          }
        }
      }

      final selected = cover;
      if (selected == null) return null;

      if (selected.url.isNotEmpty && selected.url.startsWith('http')) {
        return selected.url;
      }

      if (selected.bucket.isNotEmpty && selected.storagePath.isNotEmpty) {
        return Supabase.instance.client.storage
            .from(selected.bucket)
            .getPublicUrl(selected.storagePath);
      }

      return null;
    }

    Widget imageFromUrl(String? url) {
      if (url == null || url.isEmpty) {
        return placeholder();
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
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
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image,
            size: imageHeight * 0.3,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        child: imagesAsync.when(
          loading: placeholder,
          error: (_, __) => imageFromUrl(
            prize.imageUrl.isNotEmpty ? prize.imageUrl : null,
          ),
          data: (items) {
            final url = resolveUrl(items) ??
                (prize.imageUrl.isNotEmpty ? prize.imageUrl : null);
            return imageFromUrl(url);
          },
        ),
      ),
    );
  }
}

class _PrizeCardContent extends StatelessWidget {
  const _PrizeCardContent({
    required this.prize,
    required this.onDelete,
    required this.theme,
    required this.responsiveData,
  });

  final Prize prize;
  final VoidCallback? onDelete;
  final ThemeData theme;
  final ResponsiveCardData responsiveData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          prize.title,
          style: (responsiveData.titleStyle ?? theme.textTheme.titleMedium)?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: responsiveData.spacing * 0.4),
        Text(
          prize.sponsor,
          style: responsiveData.bodyTextStyle ?? theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: responsiveData.spacing * 0.6),
        Text(
          '€ ${(prize.valueCents / 100).toStringAsFixed(2)}',
          style: responsiveData.bodyTextStyle?.copyWith(
                fontSize: (responsiveData.bodyTextStyle?.fontSize ?? 12) * 0.85,
                fontWeight: FontWeight.w600,
              ) ??
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: responsiveData.spacing * 1.2),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: responsiveData.buttonHeight,
                child: OutlinedButton(
                  onPressed: () => context.push(
                    AppRoute.createPoolForPrize(prize.prizeId),
                    extra: prize,
                  ),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.add_circle_outline),
                ),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: responsiveData.buttonHeight,
                child: IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Elimina premio',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class PrizeCardSkeleton extends StatelessWidget {
  const PrizeCardSkeleton({super.key});

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
          cardType: CardType.prize,
        );

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveData.borderRadius)
          ),
          child: Container(
            width: responsiveData.cardWidth,
            height: responsiveData.minCardHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton per l'immagine
                Container(
                  height: responsiveData.imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(responsiveData.borderRadius)
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(responsiveData.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Skeleton per il titolo
                        Container(
                          height: 16,
                          width: double.infinity * 0.8,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: responsiveData.spacing * 0.4),
                        // Skeleton per lo sponsor
                        Container(
                          height: 14,
                          width: double.infinity * 0.6,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: responsiveData.spacing * 0.6),
                        // Skeleton per il chip del prezzo
                        Container(
                          height: 24,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const Spacer(),
                        // Skeleton per il pulsante
                        Container(
                          height: responsiveData.buttonHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
