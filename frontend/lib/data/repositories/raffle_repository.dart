import 'package:tickup/data/models/raffle_pool.dart';
import 'package:tickup/data/remote/raffle_remote_datasource.dart';

class RaffleRepository {
  final RaffleRemoteDataSource _remote = RaffleRemoteDataSource();

  Future<List<RafflePool>> fetchPools() => _remote.getPools();
  Future<RafflePool> fetchPool(String id) => _remote.getPool(id);
  Future<RafflePool> createPool(RafflePool pool) => _remote.createPool(pool);
  Future<void> updatePool(String id, RafflePool pool) =>
      _remote.updatePool(id, pool);
  Future<void> deletePool(String id) => _remote.deletePool(id);
}

