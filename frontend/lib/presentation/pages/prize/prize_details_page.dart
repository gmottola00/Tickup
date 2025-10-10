import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/features/prize/prize_images_provider.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/data/models/prize_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/presentation/routing/app_route.dart';

class PrizeDetailsPage extends ConsumerWidget {
  const PrizeDetailsPage({super.key, required this.prizeId, this.initial});

  final String prizeId;
  final Prize? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initial != null) {
      return _PrizeDetailsView(prize: initial!);
    }
    return FutureBuilder<Prize>(
      future: ref.read(prizeRepositoryProvider).fetchPrize(prizeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Errore: ${snapshot.error}')),
          );
        }
        return _PrizeDetailsView(prize: snapshot.data!);
      },
    );
  }
}

class _PrizeDetailsView extends ConsumerStatefulWidget {
  const _PrizeDetailsView({required this.prize});
  final Prize prize;

  @override
  ConsumerState<_PrizeDetailsView> createState() => _PrizeDetailsViewState();
}

class _PrizeDetailsViewState extends ConsumerState<_PrizeDetailsView> {
  late Prize _prize;
  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    _prize = widget.prize;
  }

  Future<void> _openEditForm() async {
    if (_openingEditor) return;
    setState(() => _openingEditor = true);
    try {
      final updated = await showModalBottomSheet<Prize>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => PrizeEditSheet(prize: _prize),
      );
      if (updated != null && mounted) {
        setState(() => _prize = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premio aggiornato con successo')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingEditor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceEur = (_prize.valueCents / 100).toStringAsFixed(2);
    // Prefer cover image from gallery if present (public bucket)
    final imagesAsync = ref.watch(prizeImagesProvider(_prize.prizeId));
    final poolsAsync = ref.watch(poolsProvider);
    String? headerImageUrl;
    imagesAsync.when(
      data: (items) {
        for (final img in items) {
          if (img.isCover && img.bucket == 'public-images') {
            final client = Supabase.instance.client;
            headerImageUrl = client.storage
                .from('public-images')
                .getPublicUrl(img.storagePath);
            break;
          }
        }
      },
      loading: () {},
      error: (_, __) {},
    );

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
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              title: Text(
                _prize.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (headerImageUrl ?? _prize.imageUrl).startsWith('http')
                      ? Image.network(
                          headerImageUrl ?? _prize.imageUrl,
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
                tooltip: 'Modifica',
                icon: const Icon(Icons.edit),
                onPressed: _openingEditor ? null : _openEditForm,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _PrizeGallerySection(prizeId: _prize.prizeId),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _buildBodySections(context, theme, priceEur, poolsAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySections(
    BuildContext context,
    ThemeData theme,
    String priceEur,
    AsyncValue<List<RafflePool>> poolsAsync,
  ) {
    final sections = <Widget>[
      _buildSummaryCard(theme, priceEur),
    ];

    if (_prize.description.trim().isNotEmpty) {
      sections
        ..add(const SizedBox(height: 20))
        ..add(_buildDescriptionCard(theme));
    }

    final poolSection = _buildPoolSection(context, theme, poolsAsync);
    if (poolSection != null) {
      sections
        ..add(const SizedBox(height: 28))
        ..add(poolSection);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  Widget _buildSummaryCard(ThemeData theme, String priceEur) {
    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF101822), const Color(0xFF0D1218)]
        : [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.primary.withOpacity(0.05),
          ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valore premio',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '€ $priceEur',
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ) ??
                TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricTile(
                theme,
                icon: Icons.inventory_2_outlined,
                label: 'Disponibilità',
                value: '${_prize.stock} pezzi',
              ),
              if (_prize.sponsor.isNotEmpty)
                _buildMetricTile(
                  theme,
                  icon: Icons.verified_outlined,
                  label: 'Sponsor',
                  value: _prize.sponsor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withOpacity(0.06)
        : theme.colorScheme.surface.withOpacity(0.9);

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return _buildSurfaceCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descrizione',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _prize.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5) ??
                TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPoolSection(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<RafflePool>> poolsAsync,
  ) {
    return poolsAsync.when<Widget?>(
      data: (pools) {
        RafflePool? associated;
        for (final pool in pools) {
          if (pool.prizeId == _prize.prizeId) {
            associated = pool;
            break;
          }
        }
        if (associated == null) {
          return null;
        }
        final pool = associated;
        final ticketPrice =
            (pool.ticketPriceCents / 100).toStringAsFixed(2);
        final progress = pool.ticketsRequired == 0
            ? 0.0
            : (pool.ticketsSold / pool.ticketsRequired)
                .clamp(0.0, 1.0);

        return _buildSurfaceCard(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pool collegato',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ticket € $ticketPrice • Stato ${pool.state}',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.75),
                    ) ??
                    TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.isNaN ? 0 : progress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${pool.ticketsSold}/${pool.ticketsRequired} ticket venduti',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    AppRoute.poolDetails(pool.poolId),
                    extra: pool,
                  ),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Vai al pool'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildSurfaceCard(
        theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pool non disponibile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non è stato possibile caricare il pool associato in questo momento.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurfaceCard(
    ThemeData theme, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.18),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _PrizeGallerySection extends ConsumerWidget {
  const _PrizeGallerySection({required this.prizeId});
  final String prizeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imagesAsync = ref.watch(prizeImagesControllerProvider(prizeId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Galleria', style: theme.textTheme.titleLarge),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _openReorder(context, ref),
                    icon: const Icon(Icons.swap_vert),
                    tooltip: 'Riordina',
                  ),
                  IconButton(
                    onPressed: () => _pickAndUpload(context, ref),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    tooltip: 'Aggiungi immagini',
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          imagesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Errore galleria: $e')),
                TextButton(
                  onPressed: () => ref
                      .read(prizeImagesControllerProvider(prizeId).notifier)
                      .refresh(),
                  child: const Text('Riprova'),
                )
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('Nessuna immagine. Aggiungi dalla galleria.')),
                      TextButton.icon(
                        onPressed: () => _pickAndUpload(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Aggiungi'),
                      )
                    ],
                  ),
                );
              }
              final width = MediaQuery.of(context).size.width;
              final crossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final img = items[index];
                  return _PrizeImageTile(
                    image: img,
                    onSetCover: () => ref
                        .read(prizeImagesControllerProvider(prizeId).notifier)
                        .setCover(img.imageId),
                    onDelete: () => ref
                        .read(prizeImagesControllerProvider(prizeId).notifier)
                        .delete(img.imageId),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Utente non autenticato')));
        return;
      }

      final List<PrizeImageCreate> dtos = [];
      for (final x in picked) {
        final ext = _ext(x.name);
        final key = 'prizes/$prizeId/${const Uuid().v4()}.$ext';
        final bytes = await x.readAsBytes();

        await client.storage.from('public-images').uploadBinary(
              key,
              bytes,
              fileOptions: FileOptions(
                upsert: false,
                cacheControl: 'public, max-age=3600',
                contentType: _contentType(ext),
              ),
            );
        final publicUrl = client.storage.from('public-images').getPublicUrl(key);
        dtos.add(PrizeImageCreate(
          bucket: 'public-images',
          storagePath: key,
          url: publicUrl,
        ));
      }

      final saved = await ref
          .read(prizeImagesControllerProvider(prizeId).notifier)
          .addImages(dtos);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Immagini salvate: $saved/${dtos.length}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore upload: $e')));
      }
    }
  }

  Future<void> _openReorder(BuildContext context, WidgetRef ref) async {
    final images = ref.read(prizeImagesControllerProvider(prizeId)).valueOrNull;
    if (images == null || images.isEmpty) return;
    final list = [...images];
    final result = await showModalBottomSheet<List<PrizeImage>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scroll) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Riordina immagini', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final img = list[index];
                      return ListTile(
                        key: ValueKey(img.imageId),
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: _thumb(img),
                        ),
                        title: Text(img.storagePath.split('/').last),
                        subtitle: Text(img.isCover ? 'Cover' : ''),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    },
                    itemCount: list.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Annulla'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(list),
                          child: const Text('Salva ordine'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
    if (result == null) return;
    final items = <PrizeImageReorderItem>[];
    for (int i = 0; i < result.length; i++) {
      items.add(PrizeImageReorderItem(imageId: result[i].imageId, sortOrder: i + 1));
    }
    await ref.read(prizeImagesControllerProvider(prizeId).notifier).reorder(items);
  }

  String _ext(String name) {
    final i = name.lastIndexOf('.');
    if (i == -1) return 'jpg';
    return name.substring(i + 1).toLowerCase();
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Widget _thumb(PrizeImage img) {
    final client = Supabase.instance.client;
    if (img.bucket == 'private-images') {
      return FutureBuilder<String>(
        future: client.storage
            .from('private-images')
            .createSignedUrl(img.storagePath, 3600)
            .then((v) => v),
        builder: (context, snap) {
          final url = snap.data ?? '';
          if (url.isEmpty) return _thumbPlaceholder();
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _thumbPlaceholder(),),
          );
        },
      );
    } else {
      final publicUrl = client.storage.from('public-images').getPublicUrl(img.storagePath);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(publicUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder(),),
      );
    }
  }

  Widget _thumbPlaceholder() => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      );
}

class _PrizeImageTile extends ConsumerWidget {
  const _PrizeImageTile({
    required this.image,
    required this.onSetCover,
    required this.onDelete,
  });
  final PrizeImage image;
  final VoidCallback onSetCover;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = Supabase.instance.client;
    // Resolve display URL based on bucket type
    String? publicUrl;
    if (image.bucket == 'public-images') {
      publicUrl = client.storage.from('public-images').getPublicUrl(image.storagePath);
    }
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.bucket == 'private-images'
                ? FutureBuilder<String>(
                    future: client.storage
                        .from('private-images')
                        .createSignedUrl(image.storagePath, 3600)
                        .then((v) => v),
                    builder: (context, snap) {
                      final url = snap.data ?? '';
                      if (url.isEmpty) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      );
                    },
                  )
                : Image.network(
                    publicUrl ?? image.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
          ),
        ),
        if (image.isCover)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: image.isCover ? null : onSetCover,
                icon: const Icon(Icons.star),
                tooltip: 'Imposta come cover',
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Elimina',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PrizeEditSheet extends ConsumerStatefulWidget {
  const PrizeEditSheet({super.key, required this.prize});

  final Prize prize;

  @override
  ConsumerState<PrizeEditSheet> createState() => _PrizeEditSheetState();
}

class _PrizeEditSheetState extends ConsumerState<PrizeEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sponsor;
  late final TextEditingController _stock;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.prize.title);
    _description = TextEditingController(text: widget.prize.description);
    _value = TextEditingController(
      text: (widget.prize.valueCents / 100).toStringAsFixed(2),
    );
    _imageUrl = TextEditingController(text: widget.prize.imageUrl);
    _sponsor = TextEditingController(text: widget.prize.sponsor);
    _stock = TextEditingController(text: widget.prize.stock.toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _value.dispose();
    _imageUrl.dispose();
    _sponsor.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);

    final rawEuros = _value.text.trim().replaceAll(',', '.');
    final euros = double.tryParse(rawEuros) ?? 0.0;
    final cents = (euros * 100).round();

    final updated = Prize(
      prizeId: widget.prize.prizeId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      valueCents: cents,
      imageUrl: _imageUrl.text.trim(),
      sponsor: _sponsor.text.trim(),
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      createdAt: widget.prize.createdAt,
      userId: widget.prize.userId,
    );

    try {
      await AuthService.instance.syncFromSupabase();
      final repo = ref.read(prizeRepositoryProvider);
      await repo.updatePrize(updated.prizeId, updated);
      final refreshed = await repo.fetchPrize(updated.prizeId);
      ref.invalidate(prizesProvider);
      ref.invalidate(myPrizesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(refreshed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: bottomInset + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifica premio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Chiudi',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Titolo'),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Il titolo e obbligatorio'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'La descrizione e obbligatoria'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _value,
                decoration: const InputDecoration(labelText: 'Valore (EUR)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Inserisci un importo valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sponsor,
                decoration: const InputDecoration(labelText: 'Sponsor'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) {
                    return 'Inserisci uno stock valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_as),
                  onPressed: _submitting ? null : _submit,
                  label: Text(_submitting ? 'Salvataggio...' : 'Salva modifiche'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
