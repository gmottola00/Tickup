# Tickup Monorepo

Tickup è una piattaforma di skill game con premi a estrazione. Il progetto raccoglie:

- un **backend FastAPI** che gestisce premi, pool, ticket, acquisti, likes e logiche di wallet;
- un **frontend Flutter** multipiattaforma che integra mini‑giochi, Supabase per auth/storage e UI responsive;
- tooling condiviso (Makefile, script, configurazioni) per offrire un’esperienza di sviluppo unificata.

Questo README offre la vista d’insieme. Le guide di dettaglio sono disponibili in `backend/README.md` e `frontend/README.md`.

---

## Step  Veloci per testare app con .env incluso
   ```bash
   make install
   make api        # FastAPI su 0.0.0.0:8000 (modificabile)
   make build-web            # Flutter build web
   make serve-web  
```

---

## Cosa include il repository

- **Pool e likes**: API per creare raffle, acquistare ticket, mettere/togliere “mi piace” con contatori consistenti.
- **Premi con cover immagini**: supporto per gallerie su Supabase Storage e fallback automatici lato app.
- **Supabase integration**: auth, storage, realtime e refresh token gestiti in modo trasparente.
- **Tooling dev**: Makefile con target rapidi, hot‑reload web/mobile, QR code per test su device, lint/test offerti out‑of‑the‑box.
- **Architettura modulare**: Riverpod + go_router sul frontend, servizi separati su backend con SQLAlchemy async.

---

## Struttura principale

```
Tickup/
├── backend/                 # API FastAPI + SQLAlchemy + Alembic
│   └── README.md            # Guida backend (setup, migrazioni, endpoints)
├── frontend/                # App Flutter (web, Android, iOS)
│   └── README.md            # Guida frontend (config, giochi, workflow)
├── Makefile                 # Automation full-stack
├── qrcode.png               # Ultimo QR generato da `make qr`
└── README.md                # Questo documento
```

Ulteriori cartelle (`analisi/`, script vari) sono opzionali e ad uso interno.

---

## Prerequisiti globali

| Tool             | Versione consigliata | Note                                               |
|------------------|----------------------|----------------------------------------------------|
| Flutter SDK      | ≥ 3.3 (channel stable)| Include Dart 3.3, supporto web e mobile            |
| Python           | ≥ 3.10               | Gestito via Poetry per il backend                  |
| Poetry           | 1.6+                 | Installazione dipendenze FastAPI                   |
| Make             | GNU make 3.81+       | Orchestrazione comandi condivisi                   |
| Android SDK/NDK  | API 30+, NDK 27.0.12077973 | Necessari per build mobile                      |
| Supabase Project | Opzionale ma consigliato | Auth, storage e DB PostgreSQL                  |
| qrencode         | Opzionale            | Per generare `qrcode.png`                          |

Consulta i README di progetto per requisiti aggiuntivi (es. iOS/Xcode, Docker, ecc.).

---

## Quick start

1. **Clona il repository**
   ```bash
   git clone <repo-url>
   cd Tickup
   ```

2. **Installa tutte le dipendenze**
   ```bash
   make install
   ```

3. **Configura le variabili**
   - Backend: copia `backend/.env.example` (se presente) in `backend/.env` e compila `DATABASE_URL`, chiavi Supabase, ecc.
   - Frontend: prepara i `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ENVIRONMENT`, eventuale `APP_VERSION`).

4. **Avvia i servizi di sviluppo** (due terminal separati):
   ```bash
   make api        # FastAPI su 0.0.0.0:8000 (modificabile)
   make web        # Flutter web su 0.0.0.0:8080
   ```

4. **Avvia i servizi di sviluppo** (due terminal separati):
   ```bash
   make api        # FastAPI su 0.0.0.0:8000 (modificabile)
   make build-web            # Flutter build web
   make serve-web  

5. **Opzioni utili**
   ```bash
   make build-web            # Flutter build web
   make serve-web            # Serve statico build/web
   make android              # Avvia emulatore + flutter run
   make qr                   # Genera QR con IP locale + porta frontend
   make kill-ports           # Libera 8000/8080
   ```

Tutte le variabili (`BACKEND_PORT`, `FRONTEND_PORT`, `ENV_FILE`, `EMULATOR_ID`, …) possono essere override direttamente nel comando `make`, ad esempio:

```
make BACKEND_PORT=9000 FRONTEND_PORT=3001 api
make ENV_FILE=backend/.env.local api
```

---

## Architettura in breve

### Backend (FastAPI)

- Routers REST modulari (`api/v1/routers`) per premi, pool, likes, acquisti, ticket e utenti.
- Servizi (`app/services/`) con logica atomica: ticket redemption, idempotenza likes, wallet (ledger, topup, hold).
- SQLAlchemy async + Alembic per migrazioni, Postgres/Supabase come store.
- Dipendenze condivise (`deps.py`) per gestire sessione DB e autenticazione (Supabase JWT).
- Test con pytest e fixture per database.

### Frontend (Flutter)

- Architettura modulare: `core/` (config, network, theme, realtime), `data/` (models, datasource, repository) e `presentation/` (routing, pages, Riverpod provider).
- State management con Riverpod 2: provider family per likes, caching locale, invalidation su toggle/refetch.
- Rete tramite Dio con interceptor che sincronizza token Supabase, fallback automatico su IP/porta locale.
- Supporto cover immagini: i widget `PrizeCard` e `PoolCard` leggono la galleria Supabase, calcolano l’URL pubblico e mostrano placeholder coerenti.
- Mini games e moduli Unity integrabili tramite `flutter_unity_widget`.

---

## Flussi principali

- **Prize Management**: CRUD premi con cover (`/prizes`, `/prizes/{id}/images`). Frontend aggiorna repository e provider, cache immagini in card e detail page.
- **Pool & Likes**: `/pools/all_pools`, `/pools/{id}/likes`, toggle like/unlike idempotenti. La UI propaga lo stato senza chiamate ridondanti iniziali.
- **Ticket Purchase**: endpoint `/pools/{id}/tickets` valida acquisto (`Purchase.status == CONFIRMED`) e aggiorna contatori `tickets_sold`/stato pool.
- **Wallet (in progress)**: ledger append-only, topup/withdrawal, holds per prenotare fondi.

---

## Test & Quality

| Area     | Comando                                                                          |
|----------|----------------------------------------------------------------------------------|
| Backend  | `cd backend && poetry run pytest`                                                |
| Frontend | `cd frontend && flutter analyze && flutter test`                                 |
| Web build| `cd frontend && flutter build web`                                               |

Integra questi step in CI/CD per garantire qualità costante.

---

## Configurazione & segreti

- **Backend**: `backend/.env` gestisce DB, Supabase e secret JWT. Il file non è versionato.
- **Frontend**: i valori vengono passati come `--dart-define`. In debug puoi usare un file di supporto (`.env.development`) e script wrapper.
- **Supabase**: oltre ad auth, viene usato Storage (cover images) e Realtime. Imposta bucket pubblici per le immagini dei premi.

---

## Documentazione aggiuntiva

- [backend/README.md](backend/README.md) – Migrazioni, endpoints, wallet details.
- [frontend/README.md](frontend/README.md) – Struttura codice, giochi, troubleshooting.

Per richieste o contributi apri una issue o proponi una pull request seguendo le linee guida interne.
