import 'package:tickup/data/models/prize.dart';
import 'package:tickup/data/models/raffle_pool.dart';

class PurchasePageArgs {
  const PurchasePageArgs({required this.pool, this.prize});

  final RafflePool pool;
  final Prize? prize;
}
