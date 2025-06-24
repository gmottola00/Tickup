import '../models/prize.dart';
import '../remote/prize_remote_datasource.dart';

class PrizeRepository {
  final PrizeRemoteDataSource _remote = PrizeRemoteDataSource();

  Future<Prize> fetchPrize(String id) => _remote.getPrize(id);
  Future<void> createPrize(Prize prize) => _remote.createPrize(prize);
  Future<void> updatePrize(String id, Prize prize) =>
      _remote.updatePrize(id, prize);
  Future<void> deletePrize(String id) => _remote.deletePrize(id);
}
