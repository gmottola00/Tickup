import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:tickup/data/models/prize_image.dart';
import 'package:tickup/presentation/features/prize/prize_images_provider.dart';

class ImagesHintCard extends StatelessWidget {
  const ImagesHintCard({super.key, this.onCreateTap, this.onPickTap});
  final VoidCallback? onCreateTap;
  final VoidCallback? onPickTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Immagini premio', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Per caricare immagini crea prima il premio o inserisci un ID esistente.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onCreateTap != null)
                        TextButton.icon(
                          onPressed: onCreateTap,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Crea e carica immagini'),
                        ),
                      if (onPickTap != null)
                        TextButton.icon(
                          onPressed: onPickTap,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Aggiungi immagini ora'),
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

class PrizeImagesSection extends ConsumerWidget {
  const PrizeImagesSection({super.key, required this.prizeId});
  final String prizeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imagesAsync = ref.watch(prizeImagesControllerProvider(prizeId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Immagini', style: theme.textTheme.titleLarge),
            Row(children: [
              IconButton(
                tooltip: 'Riordina',
                onPressed: () => _openReorder(context, ref),
                icon: const Icon(Icons.swap_vert),
              ),
              FilledButton.icon(
                onPressed: () => _pickAndUpload(context, ref),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Aggiungi'),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 12),
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
                onPressed: () => ref.read(prizeImagesControllerProvider(prizeId).notifier).refresh(),
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
                    const Expanded(child: Text('Nessuna immagine. Aggiungi dalla galleria.')),
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
                return PrizeImageTileSimple(
                  image: img,
                  onSetCover: () => ref.read(prizeImagesControllerProvider(prizeId).notifier).setCover(img.imageId),
                  onDelete: () => ref.read(prizeImagesControllerProvider(prizeId).notifier).delete(img.imageId),
                );
              },
            );
          },
        ),
      ],
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utente non autenticato')),
          );
        }
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

      final saved = await ref.read(prizeImagesControllerProvider(prizeId).notifier).addImages(dtos);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Immagini salvate: $saved/${dtos.length}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore upload: $e')),
        );
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
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null && context.mounted) {
      final items = <PrizeImageReorderItem>[
        for (int i = 0; i < result.length; i++)
          PrizeImageReorderItem(imageId: result[i].imageId, sortOrder: i),
      ];
      await ref.read(prizeImagesControllerProvider(prizeId).notifier).reorder(items);
    }
  }

  Widget _thumb(PrizeImage img) {
    final client = Supabase.instance.client;
    String? url;
    if (img.bucket == 'public-images') {
      url = client.storage.from('public-images').getPublicUrl(img.storagePath);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: img.bucket == 'private-images'
          ? FutureBuilder<String>(
              future: client.storage
                  .from('private-images')
                  .createSignedUrl(img.storagePath, 3600)
                  .then((v) => v),
              builder: (context, snap) {
                final s = snap.data ?? '';
                if (s.isEmpty) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return Image.network(s, fit: BoxFit.cover);
              },
            )
          : Image.network(url ?? img.url, fit: BoxFit.cover),
    );
  }

  String _ext(String name) {
    final i = name.lastIndexOf('.');
    if (i <= 0 || i == name.length - 1) return 'jpg';
    return name.substring(i + 1).toLowerCase();
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class PrizeImageTileSimple extends ConsumerWidget {
  const PrizeImageTileSimple({super.key, required this.image, required this.onSetCover, required this.onDelete});
  final PrizeImage image;
  final VoidCallback onSetCover;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = Supabase.instance.client;
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
