import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/repositories/price_repository.dart';

final prizeRepositoryProvider = Provider((ref) => PrizeRepository());

final prizesProvider = FutureProvider<List<Prize>>((ref) async {
  return ref.read(prizeRepositoryProvider).fetchPrizes();
});

final myPrizesProvider = FutureProvider<List<Prize>>((ref) async {
  return ref.read(prizeRepositoryProvider).fetchMyPrizes();
});

class PrizeNotifier extends AsyncNotifier<Prize?> {
  @override
  FutureOr<Prize?> build() => null;

  Future<void> load(String id) async {
    state = const AsyncLoading();
    try {
      final prize = await ref.read(prizeRepositoryProvider).fetchPrize(id);
      state = AsyncData(prize);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(prizeRepositoryProvider).deletePrize(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final prizeNotifierProvider =
    AsyncNotifierProvider<PrizeNotifier, Prize?>(PrizeNotifier.new);
