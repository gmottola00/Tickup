class RafflePool {
  final String poolId;
  final String prizeId;
  final int ticketPriceCents;
  final int ticketsRequired;
  final int ticketsSold;
  final String state;
  final DateTime? createdAt;

  RafflePool({
    required this.poolId,
    required this.prizeId,
    required this.ticketPriceCents,
    required this.ticketsRequired,
    required this.ticketsSold,
    required this.state,
    this.createdAt,
  });

  factory RafflePool.fromJson(Map<String, dynamic> json) => RafflePool(
        poolId: (json['pool_id'] ?? json['id']).toString(),
        prizeId: (json['prize_id'] ?? '').toString(),
        ticketPriceCents: (json['ticket_price_cents'] ?? 0) is int
            ? json['ticket_price_cents'] as int
            : int.tryParse((json['ticket_price_cents'] ?? '0').toString()) ?? 0,
        ticketsRequired: (json['tickets_required'] ?? 0) is int
            ? json['tickets_required'] as int
            : int.tryParse((json['tickets_required'] ?? '0').toString()) ?? 0,
        ticketsSold: (json['tickets_sold'] ?? 0) is int
            ? json['tickets_sold'] as int
            : int.tryParse((json['tickets_sold'] ?? '0').toString()) ?? 0,
        state: (json['state'] ?? 'OPEN').toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'prize_id': prizeId,
        'ticket_price_cents': ticketPriceCents,
        'tickets_required': ticketsRequired,
        'tickets_sold': ticketsSold,
        'state': state,
      };
}

