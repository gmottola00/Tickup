import 'package:dio/dio.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/data/models/purchase.dart';

class PurchaseRemoteDataSource {
  PurchaseRemoteDataSource({Dio? client}) : dio = client ?? DioClient().dio;

  final Dio dio;

  Future<Purchase> createPurchase(PurchaseCreateInput input) async {
    final response = await dio.post('purchases/', data: input.toJson());
    return Purchase.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Purchase>> getMyPurchases() async {
    final response = await dio.get('purchases/my');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? (data['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((item) => Purchase.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> getPurchase(String id) async {
    final response = await dio.get('purchases/$id');
    return Purchase.fromJson(response.data as Map<String, dynamic>);
  }
}
