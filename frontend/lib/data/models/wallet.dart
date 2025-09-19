enum WalletStatus { active, suspended }

extension WalletStatusX on WalletStatus {
  String get value {
    switch (this) {
      case WalletStatus.suspended:
        return 'SUSPENDED';
      case WalletStatus.active:
      default:
        return 'ACTIVE';
    }
  }

  static WalletStatus fromString(String? value) {
    switch (value) {
      case 'SUSPENDED':
        return WalletStatus.suspended;
      case 'ACTIVE':
      default:
        return WalletStatus.active;
    }
  }
}

enum WalletLedgerDirection { debit, credit }

extension WalletLedgerDirectionX on WalletLedgerDirection {
  String get value {
    switch (this) {
      case WalletLedgerDirection.credit:
        return 'CREDIT';
      case WalletLedgerDirection.debit:
      default:
        return 'DEBIT';
    }
  }

  static WalletLedgerDirection fromString(String? value) {
    switch (value) {
      case 'CREDIT':
        return WalletLedgerDirection.credit;
      case 'DEBIT':
      default:
        return WalletLedgerDirection.debit;
    }
  }
}

enum WalletLedgerReason {
  topup,
  ticketPurchase,
  refund,
  prizePayout,
  adjustment,
}

extension WalletLedgerReasonX on WalletLedgerReason {
  String get value {
    switch (this) {
      case WalletLedgerReason.topup:
        return 'TOPUP';
      case WalletLedgerReason.ticketPurchase:
        return 'TICKET_PURCHASE';
      case WalletLedgerReason.refund:
        return 'REFUND';
      case WalletLedgerReason.prizePayout:
        return 'PRIZE_PAYOUT';
      case WalletLedgerReason.adjustment:
      default:
        return 'ADJUSTMENT';
    }
  }

  static WalletLedgerReason fromString(String? value) {
    switch (value) {
      case 'TOPUP':
        return WalletLedgerReason.topup;
      case 'TICKET_PURCHASE':
        return WalletLedgerReason.ticketPurchase;
      case 'REFUND':
        return WalletLedgerReason.refund;
      case 'PRIZE_PAYOUT':
        return WalletLedgerReason.prizePayout;
      case 'ADJUSTMENT':
      default:
        return WalletLedgerReason.adjustment;
    }
  }
}

enum WalletLedgerEntryStatus { pending, posted, reversed }

extension WalletLedgerEntryStatusX on WalletLedgerEntryStatus {
  String get value {
    switch (this) {
      case WalletLedgerEntryStatus.posted:
        return 'POSTED';
      case WalletLedgerEntryStatus.reversed:
        return 'REVERSED';
      case WalletLedgerEntryStatus.pending:
      default:
        return 'PENDING';
    }
  }

  static WalletLedgerEntryStatus fromString(String? value) {
    switch (value) {
      case 'POSTED':
        return WalletLedgerEntryStatus.posted;
      case 'REVERSED':
        return WalletLedgerEntryStatus.reversed;
      case 'PENDING':
      default:
        return WalletLedgerEntryStatus.pending;
    }
  }
}

enum WalletTopupStatus { created, processing, completed, failed, cancelled }

extension WalletTopupStatusX on WalletTopupStatus {
  String get value {
    switch (this) {
      case WalletTopupStatus.processing:
        return 'PROCESSING';
      case WalletTopupStatus.completed:
        return 'COMPLETED';
      case WalletTopupStatus.failed:
        return 'FAILED';
      case WalletTopupStatus.cancelled:
        return 'CANCELLED';
      case WalletTopupStatus.created:
      default:
        return 'CREATED';
    }
  }

  static WalletTopupStatus fromString(String? value) {
    switch (value) {
      case 'PROCESSING':
        return WalletTopupStatus.processing;
      case 'COMPLETED':
        return WalletTopupStatus.completed;
      case 'FAILED':
        return WalletTopupStatus.failed;
      case 'CANCELLED':
        return WalletTopupStatus.cancelled;
      case 'CREATED':
      default:
        return WalletTopupStatus.created;
    }
  }
}

class WalletAccount {
  final String walletId;
  final String userId;
  final int balanceCents;
  final String currency;
  final WalletStatus status;
  final DateTime? createdAt;

  const WalletAccount({
    required this.walletId,
    required this.userId,
    required this.balanceCents,
    required this.currency,
    required this.status,
    this.createdAt,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    return WalletAccount(
      walletId: (json['wallet_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      balanceCents: _parseInt(json['balance_cents']),
      currency: (json['currency'] ?? 'EUR').toString(),
      status: WalletStatusX.fromString((json['status'] ?? '').toString()),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class WalletLedgerEntry {
  final int entryId;
  final String walletId;
  final WalletLedgerDirection direction;
  final int amountCents;
  final WalletLedgerReason reason;
  final WalletLedgerEntryStatus status;
  final String? refPurchaseId;
  final String? refPoolId;
  final String? refTicketId;
  final String? refExternalTxn;
  final DateTime? createdAt;

  const WalletLedgerEntry({
    required this.entryId,
    required this.walletId,
    required this.direction,
    required this.amountCents,
    required this.reason,
    required this.status,
    this.refPurchaseId,
    this.refPoolId,
    this.refTicketId,
    this.refExternalTxn,
    this.createdAt,
  });

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      entryId: _parseInt(json['entry_id']),
      walletId: (json['wallet_id'] ?? '').toString(),
      direction:
          WalletLedgerDirectionX.fromString((json['direction'] ?? '').toString()),
      amountCents: _parseInt(json['amount_cents']),
      reason: WalletLedgerReasonX.fromString((json['reason'] ?? '').toString()),
      status: WalletLedgerEntryStatusX.fromString((json['status'] ?? '').toString()),
      refPurchaseId: _parseNullableString(json['ref_purchase_id']),
      refPoolId: _parseNullableString(json['ref_pool_id']),
      refTicketId: _parseNullableString(json['ref_ticket_id']),
      refExternalTxn: _parseNullableString(json['ref_external_txn']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class WalletLedgerList {
  final List<WalletLedgerEntry> items;
  final int total;

  const WalletLedgerList({
    required this.items,
    required this.total,
  });

  factory WalletLedgerList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = rawItems is List
        ? rawItems
            .map((item) => WalletLedgerEntry.fromJson(
                (item ?? <String, dynamic>{}) as Map<String, dynamic>))
            .toList()
        : <WalletLedgerEntry>[];

    return WalletLedgerList(
      items: parsedItems,
      total: _parseInt(json['total']),
    );
  }
}

class WalletDebitCreateInput {
  final int amountCents;
  final WalletLedgerReason reason;
  final String? refPurchaseId;
  final String? refPoolId;
  final String? refTicketId;
  final String? refExternalTxn;

  const WalletDebitCreateInput({
    required this.amountCents,
    this.reason = WalletLedgerReason.ticketPurchase,
    this.refPurchaseId,
    this.refPoolId,
    this.refTicketId,
    this.refExternalTxn,
  });

  Map<String, dynamic> toJson() => {
        'amount_cents': amountCents,
        'reason': reason.value,
        if (refPurchaseId != null && refPurchaseId!.isNotEmpty)
          'ref_purchase_id': refPurchaseId,
        if (refPoolId != null && refPoolId!.isNotEmpty)
          'ref_pool_id': refPoolId,
        if (refTicketId != null && refTicketId!.isNotEmpty)
          'ref_ticket_id': refTicketId,
        if (refExternalTxn != null && refExternalTxn!.isNotEmpty)
          'ref_external_txn': refExternalTxn,
      };
}

class WalletTopupCreateInput {
  final int amountCents;
  final String provider;
  final String? providerTxnId;

  const WalletTopupCreateInput({
    required this.amountCents,
    required this.provider,
    this.providerTxnId,
  });

  Map<String, dynamic> toJson() => {
        'amount_cents': amountCents,
        'provider': provider,
        if (providerTxnId != null && providerTxnId!.isNotEmpty)
          'provider_txn_id': providerTxnId,
      };
}

class WalletTopupCompleteInput {
  final String? providerTxnId;

  const WalletTopupCompleteInput({
    this.providerTxnId,
  });

  Map<String, dynamic> toJson() => {
        if (providerTxnId != null && providerTxnId!.isNotEmpty)
          'provider_txn_id': providerTxnId,
      };
}

class WalletTopupRequest {
  final String topupId;
  final String walletId;
  final String provider;
  final String? providerTxnId;
  final int amountCents;
  final WalletTopupStatus status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const WalletTopupRequest({
    required this.topupId,
    required this.walletId,
    required this.provider,
    this.providerTxnId,
    required this.amountCents,
    required this.status,
    this.createdAt,
    this.completedAt,
  });

  factory WalletTopupRequest.fromJson(Map<String, dynamic> json) {
    return WalletTopupRequest(
      topupId: (json['topup_id'] ?? '').toString(),
      walletId: (json['wallet_id'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      providerTxnId: _parseNullableString(json['provider_txn_id']),
      amountCents: _parseInt(json['amount_cents']),
      status: WalletTopupStatusX.fromString((json['status'] ?? '').toString()),
      createdAt: _parseDate(json['created_at']),
      completedAt: _parseDate(json['completed_at']),
    );
  }
}

class WalletTopupWithEntry {
  final WalletTopupRequest topup;
  final WalletLedgerEntry ledgerEntry;

  const WalletTopupWithEntry({
    required this.topup,
    required this.ledgerEntry,
  });

  factory WalletTopupWithEntry.fromJson(Map<String, dynamic> json) {
    return WalletTopupWithEntry(
      topup: WalletTopupRequest.fromJson(
          (json['topup'] ?? <String, dynamic>{}) as Map<String, dynamic>),
      ledgerEntry: WalletLedgerEntry.fromJson(
          (json['ledger_entry'] ?? <String, dynamic>{}) as Map<String, dynamic>),
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
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
