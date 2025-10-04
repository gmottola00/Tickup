import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';

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
                _prize.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _prize.imageUrl.startsWith('http')
                      ? Image.network(
                          _prize.imageUrl,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text('EUR $priceEur'),
                        avatar: const Icon(Icons.euro, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Stock: ${_prize.stock}'),
                        avatar: const Icon(Icons.inventory_2, size: 16),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_prize.sponsor.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.business, size: 18),
                        const SizedBox(width: 6),
                        Text(_prize.sponsor, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text('Descrizione', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_prize.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  if (_prize.createdAt != null)
                    Text(
                      'Creato il: ${_prize.createdAt!.toLocal().toString().split('.').first}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
