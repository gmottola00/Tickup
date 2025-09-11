import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/repositories/raffle_repository.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';

class PoolCreatePage extends ConsumerStatefulWidget {
  const PoolCreatePage({super.key, required this.prizeId});

  final String prizeId;

  @override
  ConsumerState<PoolCreatePage> createState() => _PoolCreatePageState();
}

class _PoolCreatePageState extends ConsumerState<PoolCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController(); // in Euro
  final _required = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _price.dispose();
    _required.dispose();
    super.dispose();
  }

  Future<void> _ensureAuthHeader() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      AuthService.instance.setToken(token);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    await _ensureAuthHeader();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final euros = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    final cents = (euros * 100).round();
    final required = int.tryParse(_required.text.trim()) ?? 0;

    final pool = RafflePool(
      poolId: 'temp', // backend generates UUID, ignored on create
      prizeId: widget.prizeId,
      ticketPriceCents: cents,
      ticketsRequired: required,
      ticketsSold: 0,
      state: 'OPEN',
    );

    try {
      final repo = RaffleRepository();
      await repo.createPool(pool);
      // refresh home list
      ref.invalidate(poolsProvider);
      _show('Pool creato');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      _show('Errore nella creazione del pool');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Crea Pool')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dettagli pool',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: widget.prizeId,
                          decoration:
                              const InputDecoration(labelText: 'ID Premio'),
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _price,
                          decoration:
                              const InputDecoration(labelText: 'Prezzo ticket (€)'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          validator: (v) {
                            final n =
                                double.tryParse((v ?? '').replaceAll(',', '.'));
                            if (n == null || n <= 0) {
                              return 'Inserisci un importo valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _required,
                          decoration: const InputDecoration(
                              labelText: 'Biglietti richiesti'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) {
                              return 'Inserisci un numero valido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crea pool'),
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
