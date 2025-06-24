import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _poolsChannel;

  /// Sottoscrive la tabella `pools`
  void init({void Function(Map<String, dynamic>)? onChange}) {
    if (_poolsChannel != null) return;

    _poolsChannel = _client
        .channel('public:pools')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pools',
          callback: (payload, [ref]) {
            onChange?.call(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Chiude la connessione (logout / dispose)
  void dispose() {
    if (_poolsChannel != null) {
      _client.removeChannel(_poolsChannel!);
      _poolsChannel = null;
    }
  }

  /// Sottoscrizione generica
  RealtimeChannel subscribe({
    required String schema,
    required String table,
    required PostgresChangeEvent event,
    required void Function(Map<String, dynamic>) onEvent,
  }) {
    final ch = _client
        .channel('$schema:$table')
        .onPostgresChanges(
          schema: schema,
          table: table,
          event: event,
          callback: (payload, [__]) => onEvent(payload.newRecord),
        )
        .subscribe();
    return ch;
  }

  void unsubscribe(RealtimeChannel ch) => _client.removeChannel(ch);
}
