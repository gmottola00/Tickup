enum PurchaseType { entry, boost, retry }

extension PurchaseTypeX on PurchaseType {
  String get value {
    switch (this) {
      case PurchaseType.entry:
        return 'ENTRY';
      case PurchaseType.boost:
        return 'BOOST';
      case PurchaseType.retry:
        return 'RETRY';
    }
  }

  static PurchaseType fromString(String? value) {
    switch (value) {
      case 'BOOST':
        return PurchaseType.boost;
      case 'RETRY':
        return PurchaseType.retry;
      case 'ENTRY':
      default:
        return PurchaseType.entry;
    }
  }
}

enum PurchaseStatus { pending, confirmed, failed }

extension PurchaseStatusX on PurchaseStatus {
  String get value {
    switch (this) {
      case PurchaseStatus.confirmed:
        return 'CONFIRMED';
      case PurchaseStatus.failed:
        return 'FAILED';
      case PurchaseStatus.pending:
      default:
        return 'PENDING';
    }
  }

  static PurchaseStatus fromString(String? value) {
    switch (value) {
      case 'CONFIRMED':
        return PurchaseStatus.confirmed;
      case 'FAILED':
        return PurchaseStatus.failed;
      case 'PENDING':
      default:
        return PurchaseStatus.pending;
    }
  }
}

class Purchase {
  final String purchaseId;
  final String userId;
  final String poolId;
  final PurchaseType type;
  final int amountCents;
  final String currency;
  final String? providerTxnId;
  final PurchaseStatus status;
  final int? walletEntryId;
  final String? walletHoldId;
  final DateTime? createdAt;

  const Purchase({
    required this.purchaseId,
    required this.userId,
    required this.poolId,
    required this.type,
    required this.amountCents,
    required this.currency,
    this.providerTxnId,
    required this.status,
    this.walletEntryId,
    this.walletHoldId,
    this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: (json['purchase_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      poolId: (json['pool_id'] ?? '').toString(),
      type: PurchaseTypeX.fromString(
        (json['type'] ?? json['purchase_type'] ?? '').toString(),
      ),
      amountCents: _parseInt(json['amount_cents']),
      currency: (json['currency'] ?? 'EUR').toString(),
      providerTxnId: json['provider_txn_id']?.toString(),
      status: PurchaseStatusX.fromString((json['status'] ?? '').toString()),
      walletEntryId: _parseNullableInt(json['wallet_entry_id']),
      walletHoldId: _parseNullableString(json['wallet_hold_id']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'type': type.value,
        'amount_cents': amountCents,
        'currency': currency,
        'pool_id': poolId,
        if (providerTxnId != null && providerTxnId!.isNotEmpty)
          'provider_txn_id': providerTxnId,
        'status': status.value,
        if (walletEntryId != null) 'wallet_entry_id': walletEntryId,
        if (walletHoldId != null && walletHoldId!.isNotEmpty)
          'wallet_hold_id': walletHoldId,
      };
}

class PurchaseCreateInput {
  final PurchaseType type;
  final int amountCents;
  final String currency;
  final String? providerTxnId;
  final PurchaseStatus status;
  final String poolId;
  final int? walletEntryId;
  final String? walletHoldId;

  const PurchaseCreateInput({
    this.type = PurchaseType.entry,
    required this.amountCents,
    this.currency = 'EUR',
    this.providerTxnId,
    this.status = PurchaseStatus.pending,
    required this.poolId,
    this.walletEntryId,
    this.walletHoldId,
  });

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'amount_cents': amountCents,
        'currency': currency,
        'pool_id': poolId,
        if (providerTxnId != null && providerTxnId!.isNotEmpty)
          'provider_txn_id': providerTxnId,
        'status': status.value,
        if (walletEntryId != null) 'wallet_entry_id': walletEntryId,
        if (walletHoldId != null && walletHoldId!.isNotEmpty)
          'wallet_hold_id': walletHoldId,
      };
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String? _parseNullableString(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString();
  if (stringValue.isEmpty) return null;
  return stringValue;
}
