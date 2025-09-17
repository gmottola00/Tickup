# Tickup Monorepo

Piattaforma raffle/skill-game composta da frontend Flutter e backend FastAPI. Il backend espone le API per premi, pool e ticket; il frontend offre l app arcade con mini-giochi integrati e realtime tramite Supabase.

---

## Stack in breve

- **Frontend**: Flutter 3.3+, Riverpod 2, go_router, Dio 5, Supabase Flutter, Flame (mini-giochi)
- **Backend**: FastAPI, SQLAlchemy async, Alembic, PostgreSQL/Supabase, Poetry
- **Dev tools**: Makefile unico (`make install`, `make api`, `make web`, ecc.), Docker (opzionale), pytest / flutter test

---

## Requisiti globali

| Tool | Versione | Note |
|------|----------|------|
| Flutter SDK | ≥ 3.3 (stable) | Include Dart 3.3 |
| Python | ≥ 3.10 | Gestito tramite Poetry |
| Make | GNU make 3.81+ | Target già configurati |
| Android SDK & NDK | API 30+, NDK 27.0.12077973 | Per build mobile |
| Supabase project | opzionale ma consigliato | Auth + DB |

---

## Struttura del repository

```
backend/
├── app/
│   ├── main.py                     # Entrypoint FastAPI
│   ├── api/v1/routers/             # prize, pool, ticket, purchase, user
│   ├── services/                   # Business logic async per entità
│   ├── models/                     # SQLAlchemy models (Prize, Pool, Ticket, Purchase, User)
│   ├── schemas/                    # Schemi Pydantic
│   ├── core/                       # Config e security hooks
│   └── db/                         # Base + session + migrazioni Alembic
├── README.md                       # Guida backend dettagliata
└── pyproject.toml                  # Poetry

frontend/
├── lib/
│   ├── app.dart, main.dart         # MaterialApp.router + bootstrap Supabase
│   ├── core/                       # Config, network (Dio/AuthService), realtime, theme
│   ├── data/                       # Models, remote datasources, repositories
│   ├── presentation/               # Routing, pages, widgets, feature providers
│   └── providers/                  # Theme/navigation provider globali
├── README.md                       # Guida frontend aggiornata
└── pubspec.yaml

Makefile                            # automation full-stack
run.sh                              # helper script (se presente)
```

---

## Workflow consigliato

1. **Bootstrap**
   ```bash
   make install
   ```

2. **Avvia backend** (FastAPI + Supabase DB):
   ```bash
   make api
   ```
   - Override porte/env: `make BACKEND_PORT=9000 ENV_FILE=backend/.env.local api`

3. **Avvia frontend web** (Flutter web server + QR opzionale):
   ```bash
   make web             # http://0.0.0.0:8080
   make qr              # genera qrcode.png con l URL locale
   ```
   Per build statica: `make build-web` e `make serve-web`.

4. **Avvio mobile**:
   ```bash
   make android         # lancia emulatore (EMULATOR_ID) e avvia flutter run
   ```

5. **Altri comandi utili**:
   ```bash
   make kill-ports      # libera 8000 e 8080
   make ip              # stampa IP locale per test su device
   ```

---

## Logica dominio (overview)

- **Purchase**: registra un pagamento utente con `type` (`ENTRY`, `BOOST`, `RETRY`) e `status` (`PENDING`, `CONFIRMED`, `FAILED`). Solo acquisti `CONFIRMED` e di tipo `ENTRY` possono essere associati a ticket.
- **Ticket**: rappresenta un biglietto numerato per un pool. Alla creazione verifica che il pool sia `OPEN`, che `tickets_sold` < `tickets_required`, e aggiorna automaticamente il contatore. Quando `tickets_sold` raggiunge la soglia, lo stato del pool passa a `FULL`.
- **RafflePool**: definisce il premio, il costo del ticket e la soglia di completamento. È la base per future estrazioni (cron jobs o servizi esterni).
- **Frontend**: si collega al backend via Dio; intercetta `401` per refresh token tramite Supabase e aggiorna i provider Riverpod. Il realtime su Supabase consente update live dei pool.

---

## Testing

- **Backend**: `cd backend && poetry run pytest`
- **Frontend**: `cd frontend && flutter analyze && flutter test`

Aggiungi test di integrazione per flussi critici come purchase → ticket e UI widget per mini-giochi.

---

## Ambiente e configurazione

- File `.env` (backend) con credenziali PostgreSQL/Supabase.
- Frontend utilizza `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ENVIRONMENT`) gestiti in `EnvConfig`.
- CORS configurato in `backend/app/main.py` per consentire sviluppo con Flutter web (`http://0.0.0.0:8080`).

---

## Roadmap ad alto livello

- Completare flusso vincitori e notifiche realtime.
- Integrare provider di pagamento reale (webhook → `Purchase.status`).
- Pubblicare build mobile (Android/iOS) e web (hosting Supabase/Firebase).
- Automazione CI/CD per lint, test e deploy.

---

## Contatti

Per supporto o onboarding: riferirsi ai README di backend e frontend oppure contattare il team Tickup.
