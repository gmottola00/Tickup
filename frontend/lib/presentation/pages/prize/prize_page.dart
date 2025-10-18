import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/prize_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:tickup/presentation/routing/app_route.dart';
import 'package:tickup/presentation/widgets/backend_success_dialog.dart';
import 'package:tickup/presentation/widgets/prize_images_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:tickup/presentation/features/prize/prize_images_provider.dart';
// L'UUID viene generato dal backend alla creazione

class PrizePage extends ConsumerStatefulWidget {
  const PrizePage({super.key});
  @override
  ConsumerState<PrizePage> createState() => _PrizePageState();
}

class _PrizePageState extends ConsumerState<PrizePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _value = TextEditingController();
  // image_url e sponsor rimossi dal form: gestiti altrove
  final _stock = TextEditingController();

  bool _submitting = false;
  final List<XFile> _draftImages = [];

  Future<void> _ensureAuthHeader() async {
    // Recupera l'access token da Supabase (se loggato) e lo imposta nell'AuthService,
    // così DioClient aggiunge automaticamente l'Authorization Bearer alle richieste.
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      AuthService.instance.setToken(token);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _value.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createPrize() async {
    await _ensureAuthHeader();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final rawEuros = _value.text.trim().replaceAll(',', '.');
    final euros = double.tryParse(rawEuros) ?? 0.0;
    final cents = (euros * 100).round();

    final prize = Prize(
      // In creazione l'ID viene generato dal backend; qui è placeholder.
      prizeId: '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      valueCents: cents,
      imageUrl: '',
      sponsor: '',
      stock: int.tryParse(_stock.text.trim()) ?? 0,
    );

    try {
      final repo = ref.read(prizeRepositoryProvider);
      final created = await repo.createPrize(prize);
      // Carica eventuali immagini selezionate in bozza
      await _uploadDraftImagesIfAny(created.prizeId);
      if (!mounted) return;
      // Reset completo del form e della UI
      setState(() {
        _draftImages.clear();
      });
      _clearForm();
      FocusScope.of(context).unfocus();
      // Aggiorna lista in Home
      ref.invalidate(prizesProvider);
      ref.invalidate(myPrizesProvider);
      await BackendSuccessDialog.show(
        context,
        title: 'Premio creato',
        message: 'Vuoi creare subito un pool per questo premio?',
        barrierDismissible: false,
        actions: [
          BackendSuccessAction(
            label: 'Crea il Pool',
            icon: Icons.confirmation_number_outlined,
            isPrimary: true,
            onPressed: (ctx) {
              GoRouter.of(ctx)
                  .push(AppRoute.createPoolForPrize(created.prizeId));
            },
          ),
          BackendSuccessAction(
            label: 'I tuoi Oggetti',
            icon: Icons.inventory_2_outlined,
            onPressed: (ctx) {
              GoRouter.of(ctx).go(AppRoute.myPrizes);
            },
          ),
          BackendSuccessAction(
            label: 'Home',
            icon: Icons.home_outlined,
            onPressed: (ctx) {
              GoRouter.of(ctx).go(AppRoute.home);
            },
          ),
        ],
      );
    } catch (_) {
      _showSnackbar('Errore nella richiesta');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearForm() {
    _title.clear();
    _desc.clear();
    _value.clear();
    _stock.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prizeNotifierProvider);
    final isLoading = async.isLoading || _submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Premio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoute.home);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PrizeFormCard(
                  title: _title,
                  desc: _desc,
                  value: _value,
                  stock: _stock,
                ),
                const SizedBox(height: 24),
                ImagesHintCard(
                  onPickTap: isLoading ? null : _pickDraftImages,
                ),
                if (_draftImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DraftPrizeImagesSection(
                    images: _draftImages,
                    onRemove: (idx) =>
                        setState(() => _draftImages.removeAt(idx)),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _createPrize,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Crea premio'),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDraftImages() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;
      setState(() => _draftImages.addAll(picked));
      _showSnackbar('Immagini aggiunte in bozza: ${picked.length}');
    } catch (e) {
      _showSnackbar('Errore selezione immagini: $e');
    }
  }

  Future<void> _uploadDraftImagesIfAny(String prizeId) async {
    if (_draftImages.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      final List<PrizeImageCreate> dtos = [];
      for (final x in _draftImages) {
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
        final publicUrl =
            client.storage.from('public-images').getPublicUrl(key);
        dtos.add(PrizeImageCreate(
          bucket: 'public-images',
          storagePath: key,
          url: publicUrl,
        ));
      }
      final saved = await ref
          .read(prizeImagesControllerProvider(prizeId).notifier)
          .addImages(dtos);
      setState(() => _draftImages.clear());
      _showSnackbar('Immagini caricate: $saved/${dtos.length}');
    } catch (e) {
      _showSnackbar('Errore upload immagini: $e');
    }
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

// _LoadDeleteSection rimosso secondo il nuovo design

class DraftPrizeImagesSection extends StatelessWidget {
  const DraftPrizeImagesSection(
      {super.key, required this.images, required this.onRemove});
  final List<XFile> images;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
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
      itemCount: images.length,
      itemBuilder: (context, index) {
        final x = images[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List>(
                  future: x.readAsBytes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton.filledTonal(
                onPressed: () => onRemove(index),
                icon: const Icon(Icons.close),
                tooltip: 'Rimuovi',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrizeFormCard extends StatelessWidget {
  const _PrizeFormCard({
    required this.title,
    required this.desc,
    required this.value,
    required this.stock,
  });

  final TextEditingController title;
  final TextEditingController desc;
  final TextEditingController value;
  final TextEditingController stock;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Dettagli premio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: title,
              decoration: InputDecoration(
                labelText: 'Titolo',
                prefixIcon: const Icon(Icons.emoji_events_outlined),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.4),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Il titolo è obbligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: desc,
              decoration: InputDecoration(
                labelText: 'Descrizione',
                prefixIcon: const Icon(Icons.description_outlined),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.4),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La descrizione è obbligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: value,
              decoration: const InputDecoration(labelText: 'Valore (€)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                final raw = (v ?? '').trim().replaceAll(',', '.');
                final n = double.tryParse(raw);
                if (n == null || n < 0) return 'Inserisci un importo valido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: stock,
              decoration: InputDecoration(
                labelText: 'Stock',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.4),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Inserisci uno stock valido';
                return null;
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Potrai creare un pool per questo premio in seguito.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
