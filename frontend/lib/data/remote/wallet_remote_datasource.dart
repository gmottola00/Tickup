import 'package:dio/dio.dart';
import 'package:tickup/core/network/dio_client.dart';
import 'package:tickup/data/models/wallet.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({Dio? client}) : dio = client ?? DioClient().dio;

  final Dio dio;

  Future<WalletAccount> getMyWallet() async {
    final response = await dio.get('wallet/me');
    return WalletAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WalletLedgerList> getMyLedger({int? limit, int? offset}) async {
    final response = await dio.get(
      'wallet/me/ledger',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    return WalletLedgerList.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WalletLedgerEntry> createLedgerDebit(WalletDebitCreateInput input) async {
    final response = await dio.post(
      'wallet/me/ledger/debit',
      data: input.toJson(),
    );
    return WalletLedgerEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WalletTopupRequest> createTopup(WalletTopupCreateInput input) async {
    final response = await dio.post(
      'wallet/topups',
      data: input.toJson(),
    );
    return WalletTopupRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<WalletTopupRequest>> getTopups({int? limit, int? offset}) async {
    final response = await dio.get(
      'wallet/topups',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? (data['data'] as List?) : null) ??
            <dynamic>[];
    return list
        .map((item) => WalletTopupRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WalletTopupWithEntry> completeTopup(
    String topupId,
    WalletTopupCompleteInput input,
  ) async {
    final response = await dio.post(
      'wallet/topups/$topupId/complete',
      data: input.toJson(),
    );
    return WalletTopupWithEntry.fromJson(response.data as Map<String, dynamic>);
  }
}
