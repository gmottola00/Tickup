import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';
// L'UUID viene generato dal backend alla creazione

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
  // image_url e sponsor rimossi dal form: gestiti altrove
  final _stock = TextEditingController();

  bool _submitting = false;

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
    _idController.dispose();
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

  Future<void> _loadPrize() async {
    await _ensureAuthHeader();
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
        _value.text = (p.valueCents / 100).toStringAsFixed(2);
        _stock.text = p.stock.toString();
        _showSnackbar('Premio caricato');
      },
      loading: () {},
      error: (_, __) => _showSnackbar('Errore nel caricamento'),
    );
  }

  Future<void> _deletePrize() async {
    await _ensureAuthHeader();
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnackbar('Inserisci un ID premio');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(prizeNotifierProvider.notifier).delete(id);
      // Aggiorna lista in Home
      ref.invalidate(prizesProvider);
      _showSnackbar('Premio eliminato');
    } catch (_) {
      _showSnackbar('Errore durante l\'eliminazione');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit({bool update = false}) async {
    await _ensureAuthHeader();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final rawEuros = _value.text.trim().replaceAll(',', '.');
    final euros = double.tryParse(rawEuros) ?? 0.0;
    final cents = (euros * 100).round();

    final prize = Prize(
      // In creazione l'ID viene generato dal backend; qui è placeholder.
      prizeId: update ? _idController.text.trim() : '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      valueCents: cents,
      imageUrl: '',
      sponsor: '',
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
          // Aggiorna lista in Home
          ref.invalidate(prizesProvider);
        }
      } else {
        final created = await repo.createPrize(prize);
        _showSnackbar('Premio creato');
        // Mostra/propaga l'UUID generato dal backend
        _idController.text = created.prizeId;
        _clearForm();
        // Aggiorna lista in Home
        ref.invalidate(prizesProvider);
      }
    } catch (_) {
      _showSnackbar('Errore nella richiesta');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearForm() {
    _idController.clear();
    _title.clear();
    _desc.clear();
    _value.clear();
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
                _PrizeFormCard(
                  title: _title,
                  desc: _desc,
                  value: _value,
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

// _LoadDeleteSection rimosso secondo il nuovo design

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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
              'Suggerimento: l\'immagine del premio si gestisce nella sezione Immagini.',
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

// Image preview non più usata nel nuovo design
