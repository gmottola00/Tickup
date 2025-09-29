import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/purchase.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/data/repositories/purchase_repository.dart';
import 'package:tickup/presentation/features/wallet/wallet_provider.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/presentation/features/purchase/purchase_provider.dart';
import 'package:tickup/presentation/pages/purchase/purchase_page_args.dart';

class PurchaseCreatePage extends ConsumerStatefulWidget {
  const PurchaseCreatePage({super.key, required this.args});

  final PurchasePageArgs args;

  @override
  ConsumerState<PurchaseCreatePage> createState() => _PurchaseCreatePageState();
}

class _PurchaseCreatePageState extends ConsumerState<PurchaseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final TextEditingController _currencyController =
      TextEditingController(text: 'EUR');
  final TextEditingController _providerTxnController = TextEditingController();

  PurchaseType _type = PurchaseType.entry;
  PurchaseStatus _status = PurchaseStatus.confirmed;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final eurAmount = widget.args.pool.ticketPriceCents / 100;
    _amountController =
        TextEditingController(text: eurAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _providerTxnController.dispose();
    super.dispose();
  }

  Future<void> _syncAuthToken() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      AuthService.instance.setToken(token);
    }
  }

  Future<void> _submit() async {
    await _syncAuthToken();
    if (!_formKey.currentState!.validate()) return;

    final pool = widget.args.pool;
    final amountEur =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    final cents = (amountEur * 100).round();
    final currency = _currencyController.text.trim().toUpperCase();
    final providerTxnId = _providerTxnController.text.trim();

    setState(() => _submitting = true);
    WalletLedgerEntry? walletEntry;
    var walletDebited = false;
    try {
      if (_status == PurchaseStatus.confirmed) {
        try {
          walletEntry = await ref
              .read(walletRepositoryProvider)
              .createLedgerDebit(
                WalletDebitCreateInput(
                  amountCents: cents,
                  reason: WalletLedgerReason.ticketPurchase,
                  refPoolId: pool.poolId,
                  refExternalTxn: providerTxnId.isEmpty ? null : providerTxnId,
                ),
              );
          walletDebited = true;
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _walletDebitErrorMessage(
                  _extractErrorMessage(
                    error,
                    fallback: 'operazione non riuscita.',
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }

      final input = PurchaseCreateInput(
        type: _type,
        amountCents: cents,
        currency: currency,
        providerTxnId: providerTxnId.isEmpty ? null : providerTxnId,
        status: _status,
        poolId: pool.poolId,
        walletEntryId: walletEntry?.entryId,
      );

      final repo = ref.read(purchaseRepositoryProvider);
      await repo.createPurchase(input);
      ref.invalidate(myPurchasesProvider);
      ref.invalidate(myParticipatingPoolsProvider);
      ref.invalidate(myPoolParticipationSummariesProvider);
      ref.invalidate(poolsProvider);
      if (!mounted) return;
      final successMessage = _status == PurchaseStatus.confirmed
          ? 'Acquisto confermato! Ticket generato.'
          : 'Acquisto registrato, in attesa di conferma.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localizedInsufficientFundsMessage(
              _extractErrorMessage(
                err,
                fallback: "Errore durante la creazione dell'acquisto.",
              ),
            ),
          ),
        ),
      );
    } finally {
      if (walletDebited) {
        ref.invalidate(myWalletProvider);
        ref.invalidate(walletLedgerProvider);
      }
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _walletDebitErrorMessage(String message) {
    final normalized = _localizedInsufficientFundsMessage(message);
    if (normalized.toLowerCase().contains('saldo insufficiente')) {
      return normalized;
    }
    return 'Impossibile addebitare il wallet: $normalized';
  }

  String _localizedInsufficientFundsMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('saldo insufficiente') ||
        normalized.contains('insufficient funds')) {
      return 'Saldo insufficiente. Ricarica il wallet per partecipare al pool.';
    }
    return message;
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    String? message;
    if (error is DioException) {
      message = _messageFromResponse(error) ?? error.message;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is Error) {
      message = error.toString();
    }
    return _cleanMessage(message, fallback: fallback);
  }

  String _cleanMessage(String? message, {required String fallback}) {
    if (message == null) return fallback;
    var text = message.trim();
    if (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length).trim();
    }
    if (text.isEmpty) {
      return fallback;
    }
    return text;
  }

  String? _messageFromResponse(DioException error) {
    final data = error.response?.data;
    final responseMessage = _detailFromResponse(data);
    if (responseMessage != null && responseMessage.trim().isNotEmpty) {
      return responseMessage.trim();
    }
    return error.response?.statusMessage;
  }

  String? _detailFromResponse(Object? data) {
    if (data == null) return null;
    if (data is String) {
      return data;
    }
    if (data is Map) {
      final detail = data['detail'];
      final message = data['message'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
        if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is String && first.isNotEmpty) {
        return first;
      }
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pool = widget.args.pool;
    final prize = widget.args.prize;
    final prizeValueEuro =
        prize != null ? (prize.valueCents / 100).toStringAsFixed(2) : null;
    final theme = Theme.of(context);
    final walletAsync = ref.watch(myWalletProvider);
    final walletSection = walletAsync.when(
      data: (wallet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WalletBalanceCard(wallet: wallet),
          const SizedBox(height: 16),
        ],
      ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _WalletBalanceSkeleton(),
          SizedBox(height: 16),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Completa l\'acquisto')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                walletSection,
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
                          'Dettagli pool',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Ticket richiesti',
                          value: pool.ticketsRequired.toString(),
                        ),
                        _SummaryRow(
                          label: 'Ticket venduti',
                          value: pool.ticketsSold.toString(),
                        ),
                        _SummaryRow(
                          label: 'Prezzo ticket (EUR)',
                          value:
                              (pool.ticketPriceCents / 100).toStringAsFixed(2),
                        ),
                        if (prize != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Dettagli Oggetto',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Nome premio',
                            value: prize.title,
                          ),
                          if (prizeValueEuro != null)
                            _SummaryRow(
                              label: 'Prezzo totale premio',
                              value: '€ $prizeValueEuro',
                            ),
                          _SummaryRow(
                            label: 'Descrizione',
                            value: prize.description,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          'Dettagli acquisto',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PurchaseType>(
                          value: _type,
                          decoration:
                              const InputDecoration(labelText: 'Tipo acquisto'),
                          items: PurchaseType.values
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.value),
                                  ))
                              .toList(),
                          onChanged: (type) {
                            if (type != null) setState(() => _type = type);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Importo (€)',
                            helperText:
                                'Viene convertito automaticamente in centesimi',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator: (value) {
                            final amount = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            if (amount == null || amount <= 0) {
                              return 'Inserisci un importo valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _currencyController,
                          decoration:
                              const InputDecoration(labelText: 'Valuta'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z]'),
                            ),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (value) {
                            final curr = (value ?? '').trim();
                            if (curr.length != 3) {
                              return 'Usa un codice ISO di 3 lettere (es. EUR)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _providerTxnController,
                          decoration: const InputDecoration(
                            labelText: 'ID transazione provider',
                            hintText: 'Opzionale',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PurchaseStatus>(
                          value: _status,
                          decoration: const InputDecoration(
                              labelText: 'Stato acquisto'),
                          items: PurchaseStatus.values
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status.value),
                                  ))
                              .toList(),
                          onChanged: (status) {
                            if (status != null) {
                              setState(() => _status = status);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.payment),
                  label: const Text('Registra acquisto'),
                ),
              ],
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.wallet});

  final WalletAccount wallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo wallet disponibile',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '€ ${_formatEuro(wallet.balanceCents)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.currency_exchange, size: 16),
                  label: Text(wallet.currency),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text('Stato: ${wallet.status.value}'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceSkeleton extends StatelessWidget {
  const _WalletBalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _formatEuro(int cents) {
  return (cents / 100).toStringAsFixed(2);
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
