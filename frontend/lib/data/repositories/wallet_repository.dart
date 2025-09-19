import 'package:tickup/data/models/wallet.dart';
import 'package:tickup/data/remote/wallet_remote_datasource.dart';

class WalletRepository {
  WalletRepository({WalletRemoteDataSource? remote})
      : _remote = remote ?? WalletRemoteDataSource();

  final WalletRemoteDataSource _remote;

  Future<WalletAccount> fetchMyWallet() {
    return _remote.getMyWallet();
  }

  Future<WalletLedgerList> fetchMyLedger({int? limit, int? offset}) {
    return _remote.getMyLedger(limit: limit, offset: offset);
  }

  Future<WalletLedgerEntry> createLedgerDebit(WalletDebitCreateInput input) {
    return _remote.createLedgerDebit(input);
  }

  Future<WalletTopupRequest> createTopup(WalletTopupCreateInput input) {
    return _remote.createTopup(input);
  }

  Future<List<WalletTopupRequest>> fetchTopups({int? limit, int? offset}) {
    return _remote.getTopups(limit: limit, offset: offset);
  }

  Future<WalletTopupWithEntry> completeTopup(
    String topupId,
    WalletTopupCompleteInput input,
  ) {
    return _remote.completeTopup(topupId, input);
  }
}
