import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/repositories/raffle_repository.dart';

final raffleRepositoryProvider = Provider((ref) => RaffleRepository());

final poolsProvider = FutureProvider<List<RafflePool>>((ref) async {
  return ref.read(raffleRepositoryProvider).fetchPools();
});

final myPoolsProvider = FutureProvider<List<RafflePool>>((ref) async {
  return ref.read(raffleRepositoryProvider).fetchMyPools();
});

final likedPoolsProvider = FutureProvider<List<RafflePool>>((ref) async {
  return ref.read(raffleRepositoryProvider).fetchLikedPools();
});
