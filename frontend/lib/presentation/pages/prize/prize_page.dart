import 'package:flutter/material.dart';
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

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loadPrize() async {
    final id = _idController.text.trim();
    await ref.read(prizeNotifierProvider.notifier).load(id);
    final state = ref.read(prizeNotifierProvider);
    if (state.hasError) {
      _showSnackbar('Errore nel caricamento');
    } else if (state.value != null) {
      final p = state.value!;
      _title.text = p.title;
      _desc.text = p.description;
      _value.text = p.valueCents.toString();
      _img.text = p.imageUrl;
      _sponsor.text = p.sponsor;
      _stock.text = p.stock.toString();
      _showSnackbar('Premio caricato!');
    }
  }

  void _deletePrize() async {
    final id = _idController.text.trim();
    await ref.read(prizeNotifierProvider.notifier).delete(id);
    _showSnackbar('Premio eliminato');
  }

  void _submit({bool update = false}) async {
    if (_formKey.currentState!.validate()) {
      final uuid = Uuid();

      final prize = Prize(
        prizeId: update ? _idController.text.trim() : uuid.v4(),
        title: _title.text,
        description: _desc.text,
        valueCents: int.parse(_value.text),
        imageUrl: _img.text,
        sponsor: _sponsor.text,
        stock: int.parse(_stock.text),
      );

      try {
        final repo = ref.read(prizeRepositoryProvider);
        if (update) {
          await repo.updatePrize(_idController.text.trim(), prize);
          _showSnackbar('Premio aggiornato!');
        } else {
          await repo.createPrize(prize);
          _showSnackbar('Premio creato!');
          _clearForm();
        }
      } catch (_) {
        _showSnackbar('Errore nella richiesta');
      }
    }
  }

  void _clearForm() {
    _idController.clear();
    _title.clear();
    _desc.clear();
    _value.clear();
    _img.clear();
    _sponsor.clear();
    _stock.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prize Page')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  ElevatedButton(
                      onPressed: _loadPrize,
                      child: const Text('Carica premio')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                      onPressed: _deletePrize,
                      child: const Text('Elimina premio')),
                ],
              ),
              const Divider(),
              TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Titolo')),
              TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Descrizione')),
              TextFormField(
                  controller: _value,
                  decoration:
                      const InputDecoration(labelText: 'Valore (cent)')),
              TextFormField(
                  controller: _img,
                  decoration: const InputDecoration(labelText: 'Image URL')),
              TextFormField(
                  controller: _sponsor,
                  decoration: const InputDecoration(labelText: 'Sponsor')),
              TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(labelText: 'Stock')),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => _submit(), child: const Text('Crea premio')),
              // ElevatedButton(
              //     onPressed: () => _submit(update: true),
              //     child: const Text('Aggiorna premio')),
            ],
          ),
        ),
      ),
    );
  }
}
