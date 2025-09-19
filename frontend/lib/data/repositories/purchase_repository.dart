import 'package:tickup/data/models/purchase.dart';
import 'package:tickup/data/remote/purchase_remote_datasource.dart';

class PurchaseRepository {
  PurchaseRepository({PurchaseRemoteDataSource? remote})
      : _remote = remote ?? PurchaseRemoteDataSource();

  final PurchaseRemoteDataSource _remote;

  Future<Purchase> createPurchase(PurchaseCreateInput input) {
    return _remote.createPurchase(input);
  }

  Future<List<Purchase>> fetchMyPurchases() {
    return _remote.getMyPurchases();
  }

  Future<Purchase> fetchPurchase(String id) {
    return _remote.getPurchase(id);
  }
}
