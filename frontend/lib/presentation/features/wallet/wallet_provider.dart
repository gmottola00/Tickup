import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final myWalletProvider = FutureProvider<WalletAccount>((ref) async {
  return ref.read(walletRepositoryProvider).fetchMyWallet();
});

final walletLedgerProvider = FutureProvider<WalletLedgerList>((ref) async {
  return ref
      .read(walletRepositoryProvider)
      .fetchMyLedger(limit: 100, offset: 0);
});

final walletTopupsProvider = FutureProvider<List<WalletTopupRequest>>((ref) async {
  return ref.read(walletRepositoryProvider).fetchTopups(limit: 100);
});
