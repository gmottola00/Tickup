# Tickup — Sistema di Notifiche e Mailbox (Flutter + FastAPI + Supabase)

Questo documento descrive un'implementazione solida, scalabile e sicura per un sistema di notifiche multi‑canale (in‑app, push, email) e una mailbox (thread di messaggi) per Tickup, basato su Flutter (client), FastAPI (backend) e Supabase (Auth, Postgres, Realtime).

## Obiettivi
- Notifiche multi‑canale: in‑app (Realtime), push (FCM), email (provider esterno).
- Mailbox con thread, partecipanti, messaggi, ricevute di lettura/archiviazione per utente.
- Preferenze per utente (canali, tipi di eventi, quiet hours, lingua).
- Affidabilità: outbox pattern, worker asincrono, retry/backoff, idempotenza.
- Sicurezza: RLS in Supabase, service role per inserimenti server‑side, audit minimale.

---

## Architettura (alto livello)
- Supabase (Postgres + Realtime + Auth)
  - Storage di stato: notifiche, consegne, token push, preferenze, mailbox.
  - Realtime per aggiornamenti in‑app.
  - RLS per isolamento per utente.
- FastAPI (API + orchestrazione)
  - Espone API per creare notifiche, gestire mailbox, upsert token, preferenze.
  - Scrive su DB con service role e pubblica eventi in outbox.
- Worker asincrono (Celery/RQ/Arq)
  - Consuma outbox e invia push/email; retry, backoff, rate limit.
  - Registra esiti in `notification_deliveries`.
- Firebase Cloud Messaging (FCM)
  - Push Android/iOS (APNs tramite FCM per iOS).
- Email provider (SES/Mailgun/SendGrid)
  - Invio email con template localizzati, gestione bounce/suppression.

---

## Modello Dati (SQL)
Di seguito uno schema iniziale. Adattare nomi/constraint alle esigenze. Le tabelle sono nel `schema public`.

```sql
-- Estensioni utili
create extension if not exists pgcrypto;   -- per gen_random_uuid
create extension if not exists pg_trgm;    -- per ricerche (opzionale)

-- NOTIFICHE ---------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,                    -- es: order_created, comment_reply
  title text not null,
  body text not null,
  data jsonb not null default '{}',      -- payload aggiuntivo (deeplink, ids)
  link text,                             -- deeplink/URL opzionale
  priority smallint not null default 0,  -- 0=normal, 10=high
  status text not null default 'unread' check (status in ('unread','read','archived')),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  expires_at timestamptz
);

create index if not exists idx_notifications_user_status_created
  on public.notifications (user_id, status, created_at desc);

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  channel text not null check (channel in ('in_app','push','email')),
  status text not null check (status in ('pending','sent','failed')),
  error text,
  retries int not null default 0,
  sent_at timestamptz
);

create index if not exists idx_notification_deliveries_notif
  on public.notification_deliveries (notification_id);

-- PUSH TOKENS ------------------------------------------------------------
create table if not exists public.push_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  device_id text,
  platform text check (platform in ('android','ios','web')),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, token)
);

create index if not exists idx_push_tokens_user on public.push_tokens (user_id);

-- PREFERENZE UTENTE ------------------------------------------------------
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  locale text default 'it',
  quiet_hours jsonb default '{"start":"22:00","end":"08:00"}',
  -- Esempio di struttura: {"order_updates": {"in_app": true, "push": true, "email": false}}
  preferences jsonb not null default '{}'
);

-- MAILBOX ----------------------------------------------------------------
create table if not exists public.mail_threads (
  id uuid primary key default gen_random_uuid(),
  subject text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz
);

create table if not exists public.mail_participants (
  thread_id uuid not null references public.mail_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  muted boolean not null default false,
  pinned boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.mail_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.mail_threads(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete set null,
  body text not null,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_mail_messages_thread_created
  on public.mail_messages (thread_id, created_at desc);

create table if not exists public.mail_receipts (
  message_id uuid not null references public.mail_messages(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  primary key (message_id, recipient_id)
);

create index if not exists idx_mail_receipts_recipient_read
  on public.mail_receipts (recipient_id, read_at nulls first);

-- OUTBOX (opzionale ma consigliato) -------------------------------------
create table if not exists public.outbox_events (
  id bigserial primary key,
  event_type text not null,          -- es: notification.created, mail.message.created
  aggregate_id uuid,                 -- es: notification id
  payload jsonb not null,
  scheduled_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists idx_outbox_scheduled on public.outbox_events (processed_at, scheduled_at);
```

### RLS (Row Level Security) in Supabase
Abilitare RLS e definire policy coerenti. Il service role (usato dal backend/worker) bypassa RLS, quindi può inserire notifiche e receipts.

```sql
-- NOTIFICHE
alter table public.notifications enable row level security;
create policy "users can view own notifications"
  on public.notifications for select
  using (user_id = auth.uid());
create policy "users can update own notifications"
  on public.notifications for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
-- Nessuna policy INSERT: solo service role crea notifiche

alter table public.notification_deliveries enable row level security;
create policy "deliveries readable by owners via notification"
  on public.notification_deliveries for select
  using (exists (
    select 1 from public.notifications n
    where n.id = notification_id and n.user_id = auth.uid()
  ));
-- Insert/Update da service role/worker

-- PUSH TOKENS
alter table public.push_tokens enable row level security;
create policy "users manage own tokens"
  on public.push_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- PREFERENZE
alter table public.user_preferences enable row level security;
create policy "users manage own preferences"
  on public.user_preferences for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- MAILBOX
alter table public.mail_threads enable row level security;
create policy "participants can read threads"
  on public.mail_threads for select
  using (exists (
    select 1 from public.mail_participants p
    where p.thread_id = mail_threads.id and p.user_id = auth.uid()
  ));
create policy "creator can insert thread"
  on public.mail_threads for insert
  with check (created_by = auth.uid());

alter table public.mail_participants enable row level security;
create policy "participants can read participants of their threads"
  on public.mail_participants for select
  using (exists (
    select 1 from public.mail_participants self
    where self.thread_id = mail_participants.thread_id and self.user_id = auth.uid()
  ));
-- Inserimenti/modifiche via backend (service role) quando si aggiungono membri

alter table public.mail_messages enable row level security;
create policy "participants can read messages"
  on public.mail_messages for select
  using (exists (
    select 1 from public.mail_participants p
    where p.thread_id = mail_messages.thread_id and p.user_id = auth.uid()
  ));
create policy "participants can send messages"
  on public.mail_messages for insert
  with check (exists (
    select 1 from public.mail_participants p
    where p.thread_id = mail_messages.thread_id and p.user_id = auth.uid()
  ) and sender_id = auth.uid());

alter table public.mail_receipts enable row level security;
create policy "recipients manage own receipts"
  on public.mail_receipts for select using (recipient_id = auth.uid());
create policy "recipients update own receipts"
  on public.mail_receipts for update using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());
-- Insert tipicamente via backend per tutti i destinatari del messaggio
```

Suggerimenti:
- Considera viste/materialized views per contatori `unread` per thread/utente.
- Usa `generated columns` o trigger per aggiornare `last_message_at` su `mail_threads`.

Esempio trigger per `last_message_at`:
```sql
create or replace function public.set_thread_last_message_at()
returns trigger language plpgsql as $$
begin
  update public.mail_threads set last_message_at = new.created_at where id = new.thread_id;
  return new;
end; $$;

create trigger trg_mail_messages_last
after insert on public.mail_messages
for each row execute function public.set_thread_last_message_at();
```

---

## Flussi Principali
- Generazione notifica
  - Evento business (FastAPI) → inserisce riga in `notifications` e, nella stessa transazione, riga in `outbox_events` (`notification.created`).
- In‑app realtime
  - Flutter si sottoscrive a `notifications` filtrate per `auth.uid()`; aggiorna lista e badge.
- Push
  - Worker legge `outbox_events`, rispetta preferenze/quiet hours, colleziona `push_tokens` e invia via FCM. Salva esito in `notification_deliveries` con idempotency key (`notification_id + channel`).
- Email
  - Worker prepara contenuto da template (locale da `user_preferences.locale`), invia tramite provider e registra esito in `notification_deliveries`.
- Mailbox
  - Creazione thread → inserimento thread + partecipanti.
  - Invio messaggio → inserimento in `mail_messages` e `mail_receipts` per ciascun partecipante (escluso sender). Realtime su thread.

---

## API FastAPI (proposta)
Rotte minime e schemi. Autenticazione: JWT di Supabase verificato da FastAPI; azioni server con service role.

- Notifiche
  - `POST /notifications` (service role): crea una notifica per un utente.
  - `GET /me/notifications?status=&cursor=`: lista notifiche dell’utente corrente (paginazione keyset).
  - `PATCH /me/notifications/{id}:read` → set `status=read`, `read_at=now()`.
  - `PATCH /me/notifications/{id}:archive`.
- Push Token
  - `PUT /me/push-token` → upsert `push_tokens` (token, device_id, platform).
  - `DELETE /me/push-token/{token}`.
- Preferenze
  - `GET /me/preferences` / `PUT /me/preferences`.
- Mailbox
  - `POST /mail/threads` → crea thread e (opzionale) partecipanti.
  - `GET /mail/threads?cursor=` → thread dove l’utente è partecipante.
  - `GET /mail/threads/{id}/messages?cursor=` → messaggi del thread.
  - `POST /mail/threads/{id}/messages` → invia messaggio.
  - `PATCH /mail/messages/{id}:read` (aggiorna `mail_receipts` per l’utente corrente).

Esempi di payload:
```json
// POST /notifications (service role)
{
  "user_id": "<uuid>",
  "type": "task_assigned",
  "title": "Nuovo task assegnato",
  "body": "Ti è stato assegnato il task #123",
  "data": {"task_id": 123, "deep_link": "tickup://tasks/123"},
  "priority": 10
}
```

```json
// PUT /me/push-token
{
  "token": "fcm-token",
  "device_id": "device-uuid",
  "platform": "android"
}
```

---

## Integrazione Flutter
Dipendenze suggerite:
- `supabase_flutter`
- `firebase_messaging`
- `flutter_local_notifications`

### Registrazione token FCM
```dart
final messaging = FirebaseMessaging.instance;
final token = await messaging.getToken();
if (token != null) {
  await supabase.from('push_tokens').upsert({
    'user_id': supabase.auth.currentUser!.id,
    'token': token,
    'device_id': await _resolveDeviceId(),
    'platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web'),
  }, onConflict: 'user_id,token');
}

FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  await supabase.from('push_tokens').upsert({
    'user_id': supabase.auth.currentUser!.id,
    'token': newToken,
    'device_id': await _resolveDeviceId(),
    'platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web'),
  });
});
```

### Realtime per notifiche in‑app
```dart
final uid = supabase.auth.currentUser!.id;
final channel = supabase
  .channel('public:notifications')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'notifications',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: uid,
    ),
    callback: (payload) {
      final row = payload.newRecord;
      // Aggiorna stato/UI, badge, ecc.
    },
  )
  .subscribe();
```

### Mostrare notifiche locali in foreground
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  final notification = message.notification;
  if (notification != null) {
    await localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails('tickup_default', 'General'),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['deep_link'],
    );
  }
});
```

### Repository notifiche (scheletro)
```dart
class NotificationsRepository {
  final SupabaseClient supabase;
  NotificationsRepository(this.supabase);

  Future<List<Map<String, dynamic>>> fetch({String? beforeId, int limit = 20}) async {
    var query = supabase
        .from('notifications')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(limit);
    if (beforeId != null) {
      final before = await supabase.from('notifications').select('created_at').eq('id', beforeId).single();
      query = query.lt('created_at', before['created_at']);
    }
    return await query;
  }

  Future<void> markAsRead(String id) async {
    await supabase.from('notifications').update({'status': 'read', 'read_at': DateTime.now().toIso8601String()}).eq('id', id);
  }

  Future<void> archive(String id) async {
    await supabase.from('notifications').update({'status': 'archived'}).eq('id', id);
  }
}
```

### Mailbox repository (scheletro)
```dart
class MailboxRepository {
  final SupabaseClient supabase;
  MailboxRepository(this.supabase);

  Future<List<Map<String, dynamic>>> threads({String? before, int limit = 20}) async {
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase.rpc('get_user_threads', params: {'p_user_id': uid, 'p_limit': limit, 'p_before': before});
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> messages(String threadId, {String? before, int limit = 50}) async {
    var q = supabase.from('mail_messages').select().eq('thread_id', threadId).order('created_at', ascending: false).limit(limit);
    if (before != null) q = q.lt('created_at', before);
    return List<Map<String, dynamic>>.from(await q);
  }

  Future<void> sendMessage(String threadId, String body, {Map<String, dynamic>? data}) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('mail_messages').insert({
      'thread_id': threadId,
      'sender_id': uid,
      'body': body,
      'data': data ?? {},
    });
  }

  Future<void> markRead(String messageId) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('mail_receipts').update({'read_at': DateTime.now().toIso8601String()}).match({'message_id': messageId, 'recipient_id': uid});
  }
}
```

Nota: per una query efficiente dei thread per utente, si può creare una funzione SQL (`rpc get_user_threads`) o una vista che unisce `mail_threads` + ultimi messaggi + contatore `unread`.

---

## Backend FastAPI (scheletro)
Esempio minimale, lasciando libertà di usare `supabase-py` o SQLAlchemy/asyncpg con la connessione Postgres di Supabase.

```python
# models.py (Pydantic)
from pydantic import BaseModel, Field
from typing import Optional, Any, Dict

class NotificationCreate(BaseModel):
    user_id: str
    type: str
    title: str
    body: str
    data: Dict[str, Any] = Field(default_factory=dict)
    priority: int = 0

class PushToken(BaseModel):
    token: str
    device_id: Optional[str]
    platform: str  # android|ios|web
```

```python
# routes.py (estratto)
from fastapi import APIRouter, Depends
from .models import NotificationCreate, PushToken

router = APIRouter()

@router.post('/notifications', status_code=201)
async def create_notification(payload: NotificationCreate):
    # 1) INSERT INTO notifications
    # 2) INSERT INTO outbox_events (event_type='notification.created', payload)
    # Usare transazione e service role
    return {"ok": True}

@router.put('/me/push-token')
async def upsert_push_token(pt: PushToken, user=Depends(require_user)):
    # Upsert in push_tokens per user.id
    return {"ok": True}
```

### Worker (RQ/Celery/Arq) — pseudo‑codice
```python
# task: process_notification_outbox
for event in fetch_unprocessed_outbox('notification.created'):
    notif = get_notification(event.aggregate_id)
    prefs = get_user_preferences(notif.user_id)
    # In‑app: nulla da fare, Realtime pensa al client
    if prefs.allows_push(notif.type):
        tokens = get_push_tokens(notif.user_id)
        send_fcm(tokens, notif)
        record_delivery(notif.id, 'push', status='sent')
    if prefs.allows_email(notif.type) and not in_quiet_hours(prefs):
        send_email(notif.user_id, render_template(notif))
        record_delivery(notif.id, 'email', status='sent')
    mark_outbox_processed(event.id)
```

Idempotenza: usare `ON CONFLICT DO NOTHING` su `notification_deliveries` con chiave unica `(notification_id, channel)`.

```sql
alter table public.notification_deliveries
  add constraint uq_notification_channel unique (notification_id, channel);
```

---

## Configurazione e Setup
- Variabili d’ambiente backend
  - `SUPABASE_DB_URL` (connessione Postgres) o client `supabase-py` con `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`.
  - `FCM_SERVER_KEY` (Firebase)
  - `EMAIL_PROVIDER_API_KEY`, `EMAIL_FROM` (SES/Mailgun/SendGrid)
- Firebase
  - Progetto FCM, file `google-services.json` (Android) e `GoogleService-Info.plist` (iOS).
  - Canali notifiche Android (importanza/suono), permessi iOS.
- Email
  - Dominio verificato con SPF/DKIM/DMARC.
  - Template versionati (Jinja2) e localizzati.
- Supabase
  - Applicare le migrazioni SQL in `supabase/migrations` o dal dashboard SQL.
  - Abilitare Realtime sulle tabelle necessarie (notifications, mail_messages se serve).

---

## Monitoraggio e Affidabilità
- Metriche: invii per canale, tasso errore, latenza, backlog outbox.
- Log strutturati con `notification_id`/`thread_id` per correlazione.
- Retry con backoff esponenziale e DLQ per fallimenti permanenti.
- Outbox pattern per evitare perdite in caso di crash.

---

## Roadmap consigliata
1) Tabelle + indici + RLS + migrazione
2) API minime notifiche (`GET/POST`, `PATCH read/archive`)
3) Flutter: UI in‑app + Realtime + badge
4) FCM: lifecycle token, foreground/background handlers
5) Email: provider + template + preferenze/quiet hours
6) Mailbox: thread, messages, receipts + UI, RPC per thread list
7) Outbox/Worker: retry, idempotenza, metriche

---

## Testing
- Unità: repository Flutter (mappatura JSON ↔ DTO), funzioni FastAPI.
- Integrazione: round‑trip crea notifica → Realtime ricevuta → markAsRead.
- End‑to‑end: push reale su dispositivo di test; email su sandbox provider.
- Sicurezza: test RLS con utenti diversi (accesso negato a dati altrui).

---

## Note e suggerimenti
- Paginazione: preferire keyset (coppia `created_at,id`) per liste grandi.
- Localizzazione: passare `locale` nel payload e nei template.
- Deep link: usare `data.deep_link` per navigare direttamente al dettaglio (task/thread).
- Rate limiting: opzionale su eventi rumorosi; valutare digest email.

---

## Appendice: RPC per elenco thread (facoltativo)
Esempio di funzione per ottenere thread con ultimo messaggio e conteggio unread.

```sql
create or replace function public.get_user_threads(p_user_id uuid, p_limit int default 20, p_before timestamptz default null)
returns table (
  id uuid,
  subject text,
  last_message_at timestamptz,
  unread_count int
) language sql stable as $$
  select t.id, t.subject, t.last_message_at,
         coalesce((
           select count(*) from public.mail_receipts r
           join public.mail_messages m on m.id = r.message_id
           where r.recipient_id = p_user_id and r.read_at is null and m.thread_id = t.id
         ), 0) as unread_count
  from public.mail_threads t
  where exists (
    select 1 from public.mail_participants p where p.thread_id = t.id and p.user_id = p_user_id
  )
  and (p_before is null or t.last_message_at < p_before)
  order by t.last_message_at desc nulls last
  limit p_limit
$$;
```

---

Se vuoi, posso generare migrazioni SQL pronte per Supabase, scheletri di repository Flutter più completi e gli endpoint FastAPI con `supabase-py` o SQLAlchemy.
