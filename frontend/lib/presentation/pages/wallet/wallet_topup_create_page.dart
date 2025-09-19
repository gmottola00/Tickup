import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/presentation/features/wallet/wallet_provider.dart';

class WalletTopupCreatePage extends ConsumerStatefulWidget {
  const WalletTopupCreatePage({super.key});

  @override
  ConsumerState<WalletTopupCreatePage> createState() => _WalletTopupCreatePageState();
}

class _WalletTopupCreatePageState extends ConsumerState<WalletTopupCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _providerController = TextEditingController();
  final _providerTxnController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _providerController.dispose();
    _providerTxnController.dispose();
    super.dispose();
  }

  Future<void> _ensureAuthHeader() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      AuthService.instance.setToken(token);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    await _ensureAuthHeader();
    if (!_formKey.currentState!.validate()) return;

    final amountEuro =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
    final amountCents = (amountEuro * 100).round();
    final provider = _providerController.text.trim();
    final providerTxnId = _providerTxnController.text.trim();

    setState(() => _submitting = true);
    final repo = ref.read(walletRepositoryProvider);

    try {
      final input = WalletTopupCreateInput(
        amountCents: amountCents,
        provider: provider,
        providerTxnId: providerTxnId.isEmpty ? null : providerTxnId,
      );
      await repo.createTopup(input);
      ref.invalidate(walletTopupsProvider);
      ref.invalidate(myWalletProvider);
      _showMessage('Richiesta di ricarica creata');
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage('Errore nella creazione della ricarica');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova ricarica wallet'),
      ),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dettagli ricarica',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Importo (€)',
                            hintText: 'Es. 20,00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          validator: (value) {
                            final parsed = double.tryParse(
                                (value ?? '').replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) {
                              return 'Inserisci un importo valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _providerController,
                          decoration: const InputDecoration(
                            labelText: 'Provider',
                            hintText: 'Es. Stripe, PayPal',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Il provider è obbligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _providerTxnController,
                          decoration: const InputDecoration(
                            labelText: 'ID transazione (facoltativo)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crea ricarica'),
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
