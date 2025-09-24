import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickup/core/network/auth_service.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/repositories/raffle_repository.dart';
import 'package:tickup/presentation/features/pool/pool_provider.dart';
import 'package:tickup/presentation/features/prize/prize_provider.dart';

const _commissionRate = 0.05;

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
  bool _prizeLoading = true;
  Prize? _prize;
  String? _prizeError;
  int? _selectedTickets;

  @override
  void initState() {
    super.initState();
    _loadPrize();
  }

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

  Future<void> _loadPrize() async {
    setState(() {
      _prizeLoading = true;
      _prizeError = null;
    });
    try {
      final prize =
          await ref.read(prizeRepositoryProvider).fetchPrize(widget.prizeId);
      if (!mounted) return;
      setState(() {
        _prize = prize;
        _prizeLoading = false;
      });
      _updatePriceForTickets(_selectedTickets);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prize = null;
        _prizeLoading = false;
        _prizeError = 'Impossibile caricare il premio.';
      });
    }
  }

  void _updatePriceForTickets(int? tickets) {
    if (tickets == null || _prize == null) {
      _price.text = '';
      return;
    }
    final prizeValueEuro = _prize!.valueCents / 100;
    final totalValueEuro = prizeValueEuro * (1 + _commissionRate);
    final priceEuro = totalValueEuro / tickets;
    _price.text = priceEuro.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    await _ensureAuthHeader();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final euros = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    final cents = (euros * 100).round();
    final required = _selectedTickets ?? 0;

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
    } catch (error) {
      _show(_creationErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _creationErrorMessage(Object error) {
    final message = _extractErrorMessage(error);
    if (message.toLowerCase().contains('esiste già un pool')) {
      return 'Questo premio è già associato a un altro pool. Elimina o chiudi il pool esistente prima di crearne uno nuovo.';
    }
    return message;
  }

  String _extractErrorMessage(Object error) {
    String? message;
    if (error is DioException) {
      message = _detailFromResponse(error.response?.data) ?? error.message;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is Error) {
      message = error.toString();
    }
    final cleaned = message?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return 'Errore nella creazione del pool';
    }
    return cleaned.replaceFirst(RegExp('^Exception: '), '').trim();
  }

  String? _detailFromResponse(Object? data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Crea Pool')),
      body: Stack(
        children: [
          _buildBody(context),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_prizeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prizeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_prizeError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadPrize,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    final prize = _prize;
    if (prize == null) {
      return const Center(child: Text('Premio non disponibile.'));
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PrizeInfoCard(prize: prize),
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    decoration: const InputDecoration(labelText: 'ID Premio'),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Prezzo ticket (€)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    readOnly: true,
                    enabled: _selectedTickets != null,
                    validator: (v) {
                      if (_selectedTickets == null || (v ?? '').isEmpty) {
                        return 'Seleziona il numero di biglietti';
                      }
                      final n =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (n == null || n <= 0) {
                        return 'Inserisci un importo valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedTickets,
                    decoration: const InputDecoration(
                      labelText: 'Biglietti richiesti',
                    ),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10 biglietti')),
                      DropdownMenuItem(value: 20, child: Text('20 biglietti')),
                      DropdownMenuItem(value: 30, child: Text('30 biglietti')),
                      DropdownMenuItem(value: 40, child: Text('40 biglietti')),
                      DropdownMenuItem(value: 50, child: Text('50 biglietti')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTickets = value;
                        _required.text = value?.toString() ?? '';
                        _updatePriceForTickets(value);
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleziona il numero di biglietti';
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
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Crea pool'),
          ),
        ],
      ),
    );
  }
}

class _PrizeInfoCard extends StatelessWidget {
  const _PrizeInfoCard({required this.prize});

  final Prize prize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseValue = prize.valueCents / 100;
    final commissionValue = baseValue * _commissionRate;
    final totalValue = baseValue + commissionValue;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prize.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.euro, size: 18),
                const SizedBox(width: 6),
                Text('Valore premio: € ${baseValue.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Commissione (${(_commissionRate * 100).toStringAsFixed(0)}%): € ${commissionValue.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Totale pool: € ${totalValue.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (prize.sponsor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business, size: 18),
                  const SizedBox(width: 6),
                  Text(prize.sponsor, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (prize.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                prize.description,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
