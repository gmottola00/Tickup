import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
import 'package:uuid/uuid.dart';

class PrizePage extends ConsumerStatefulWidget {
  const PrizePage({super.key});
  @override
  ConsumerState<PrizePage> createState() => _PrizePageState();
}

class _PrizePageState extends ConsumerState<PrizePage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _value = TextEditingController();
  final _img = TextEditingController();
  final _sponsor = TextEditingController();
  final _stock = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _title.dispose();
    _desc.dispose();
    _value.dispose();
    _img.dispose();
    _sponsor.dispose();
    _stock.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadPrize() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnackbar('Inserisci un ID premio');
      return;
    }
    await ref.read(prizeNotifierProvider.notifier).load(id);
    final state = ref.read(prizeNotifierProvider);
    state.when(
      data: (p) {
        if (p == null) {
          _showSnackbar('Nessun premio trovato');
          return;
        }
        _title.text = p.title;
        _desc.text = p.description;
        _value.text = p.valueCents.toString();
        _img.text = p.imageUrl;
        _sponsor.text = p.sponsor;
        _stock.text = p.stock.toString();
        _showSnackbar('Premio caricato');
      },
      loading: () {},
      error: (_, __) => _showSnackbar('Errore nel caricamento'),
    );
  }

  Future<void> _deletePrize() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnackbar('Inserisci un ID premio');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(prizeNotifierProvider.notifier).delete(id);
      _showSnackbar('Premio eliminato');
    } catch (_) {
      _showSnackbar('Errore durante l\'eliminazione');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit({bool update = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final uuid = const Uuid();
    final prize = Prize(
      prizeId: update ? _idController.text.trim() : uuid.v4(),
      title: _title.text.trim(),
      description: _desc.text.trim(),
      valueCents: int.tryParse(_value.text.trim()) ?? 0,
      imageUrl: _img.text.trim(),
      sponsor: _sponsor.text.trim(),
      stock: int.tryParse(_stock.text.trim()) ?? 0,
    );

    try {
      final repo = ref.read(prizeRepositoryProvider);
      if (update) {
        final id = _idController.text.trim();
        if (id.isEmpty) {
          _showSnackbar('Inserisci ID per aggiornare');
        } else {
          await repo.updatePrize(id, prize);
          _showSnackbar('Premio aggiornato');
        }
      } else {
        await repo.createPrize(prize);
        _showSnackbar('Premio creato');
        _clearForm(keepId: false);
      }
    } catch (_) {
      _showSnackbar('Errore nella richiesta');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearForm({bool keepId = true}) {
    if (!keepId) _idController.clear();
    _title.clear();
    _desc.clear();
    _value.clear();
    _img.clear();
    _sponsor.clear();
    _stock.clear();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prizeNotifierProvider);
    final isLoading = async.isLoading || _submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Premio')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _LoadDeleteSection(
                  idController: _idController,
                  onLoad: _loadPrize,
                  onDelete: _deletePrize,
                ),
                const SizedBox(height: 16),
                _PrizeFormCard(
                  title: _title,
                  desc: _desc,
                  value: _value,
                  img: _img,
                  sponsor: _sponsor,
                  stock: _stock,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            isLoading ? null : () => _submit(update: false),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Crea premio'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            isLoading ? null : () => _submit(update: true),
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Aggiorna esistente'),
                      ),
                    ),
                  ],
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
}

class _LoadDeleteSection extends StatelessWidget {
  const _LoadDeleteSection({
    required this.idController,
    required this.onLoad,
    required this.onDelete,
  });

  final TextEditingController idController;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carica / Elimina',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: idController,
                    decoration: const InputDecoration(
                        labelText: 'ID Premio', hintText: 'uuid...'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: onLoad,
                  icon: const Icon(Icons.download),
                  label: const Text('Carica'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Elimina'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrizeFormCard extends StatelessWidget {
  const _PrizeFormCard({
    required this.title,
    required this.desc,
    required this.value,
    required this.img,
    required this.sponsor,
    required this.stock,
  });

  final TextEditingController title;
  final TextEditingController desc;
  final TextEditingController value;
  final TextEditingController img;
  final TextEditingController sponsor;
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
            Text(
              'Dettagli premio',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Titolo'),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Il titolo è obbligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descrizione'),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La descrizione è obbligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: value,
              decoration: const InputDecoration(labelText: 'Valore (cent)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Inserisci un numero valido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: img,
              decoration: const InputDecoration(
                  labelText: 'Image URL', hintText: 'https://...'),
            ),
            const SizedBox(height: 8),
            _ImagePreview(urlController: img),
            const SizedBox(height: 12),
            TextFormField(
              controller: sponsor,
              decoration: const InputDecoration(labelText: 'Sponsor'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: stock,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Inserisci uno stock valido';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.urlController});
  final TextEditingController urlController;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  late String _url;

  @override
  void initState() {
    super.initState();
    _url = widget.urlController.text;
    widget.urlController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final next = widget.urlController.text;
    if (next != _url) {
      setState(() => _url = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _url.startsWith('http');
    if (!valid) {
      return Text(
        'Nessuna anteprima',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          _url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Text('Immagine non disponibile'),
          ),
        ),
      ),
    );
  }
}
