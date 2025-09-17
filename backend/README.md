# Tickup Backend

Backend API di Tickup costruita con **FastAPI**, **SQLAlchemy async**, **Alembic** e Supabase/PostgreSQL. Espone endpoint REST per gestire premi, pool a biglietti, acquisti e assegnazione ticket.

---

## Struttura del progetto

```
app/
├── main.py                    # Istanzia FastAPI e registra router v1
├── core/
│   ├── config.py              # Settings (Pydantic BaseSettings)
│   └── security.py            # Hook per auth / JWT
├── api/
│   └── v1/
│       ├── auth.py            # Helpers per ricavare lo user id
│       ├── deps.py            # Dipendenze condivise (sessione DB, ecc.)
│       └── routers/
│           ├── pool.py        # Endpoint CRUD raffle pool
│           ├── prize.py       # Endpoint CRUD prize
│           ├── purchase.py    # Endpoint registro acquisti
│           ├── ticket.py      # Endpoint gestione ticket
│           └── user.py        # Endpoint utenti (seed/demo)
├── models/
│   ├── pool.py                # Modello SQLAlchemy RafflePool
│   ├── prize.py               # Modello SQLAlchemy Prize
│   ├── purchase.py            # Modello SQLAlchemy Purchase
│   ├── ticket.py              # Modello SQLAlchemy Ticket
│   └── user.py                # Modello SQLAlchemy AppUser
├── schemas/
│   ├── pool.py                # Schemi Pydantic Pool
│   ├── prize.py               # Schemi Pydantic Prize
│   ├── purchase.py            # Schemi Pydantic Purchase
│   ├── ticket.py              # Schemi Pydantic Ticket
│   └── user.py                # Schemi Pydantic User
├── services/
│   ├── pool.py                # Logica async CRUD Pool
│   ├── prize.py               # Logica async CRUD Prize
│   ├── purchase.py            # Logica async CRUD Purchase
│   ├── ticket.py              # Ticket + business rules pool
│   └── user.py                # Utilita per l entita utente
├── clients/
│   └── supabase.py            # Client Supabase (se necessario)
└── db/
    ├── base.py                # Base declarative SQLAlchemy
    ├── session.py             # Engine async, session factory
    └── migrations/            # Script Alembic

tests/                         # Test unitari / integrazione (pytest)
alembic.ini                    # Config Alembic
pyproject.toml                 # Configurazione Poetry
README.md                      # Questo file
.env                           # Variabili ambiente (non versionato)
```

---

## Prerequisiti

- Python 3.10+
- [Poetry](https://python-poetry.org/)
- Database PostgreSQL (Supabase consigliato)
- Facoltativo: `make` + `qrencode` (gia usati nel workflow full-stack)

---

## Setup rapido (dalla root del monorepo)

1. Installa le dipendenze backend/frontend con il target condiviso:
   ```bash
   make install
   ```
2. Crea `backend/.env` partendo da questo template:
   ```dotenv
   DATABASE_URL=postgresql+asyncpg://postgres:password@host.supabase.co:5432/postgres
   SUPABASE_URL=https://host.supabase.co
   SUPABASE_KEY=service_key
   SUPABASE_JWT=jwt_secret
   ```
3. Esegui le migrazioni Alembic (vedi sezione dedicata) per popolare il database.

### Avvio con Makefile

Per lanciare l API basta usare il target `api` del Makefile di progetto:

```bash
make api
```

Il comando equivale a:
```bash
poetry run uvicorn app.main:app \
  --host 0.0.0.0 \
  --port "$BACKEND_PORT" \
  --env-file "$ENV_FILE" \
  --reload
```
- `BACKEND_PORT` (default `8000`) e `ENV_FILE` (default `backend/.env`) possono essere sovrascritti al volo, es. `make BACKEND_PORT=9000 ENV_FILE=.env.staging api`.
- L API resta raggiungibile su `http://localhost:BACKEND_PORT`, con Swagger UI su `/docs` e ReDoc su `/redoc`.

Per chiudere rapidamente porte occupate dal backend o dal web server puoi usare `make kill-ports` (libera `8000` e `8080`).

### Avvio manuale (alternativa)

Se preferisci eseguire il backend senza Makefile:
```bash
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file backend/.env --reload
```

---

## Database e migrazioni

```bash
cd backend

# Genera struttura iniziale (solo la prima volta)
poetry run alembic init app/db/migrations

# Aggiorna alembic.ini con la tua DATABASE_URL

# Crea nuova migration automatica
poetry run alembic revision --autogenerate -m "descrizione"

# Applica l ultima migration
poetry run alembic upgrade head
```

---

## Entita principali

### Prize
Premio messo in palio. Campi chiave: `prize_id` (UUID), `title`, `description`, `value_cents`, `stock`, metadati sponsor e `created_at`.

### RafflePool
Pool di biglietti legato a un premio:
- `ticket_price_cents`: costo di ogni ticket
- `tickets_required`: soglia per dichiarare il pool completo
- `tickets_sold`: contatore aggiornato dagli acquisti
- `state`: `OPEN` → `FULL` → (eventuale) `STARTED`/`CANCELLED`

### Purchase
Registro transazioni utente. Vincola ogni ticket a un pagamento con:
- `purchase_id` (UUID), `user_id`
- `type`: `ENTRY`, `BOOST`, `RETRY`
- `status`: `PENDING`, `CONFIRMED`, `FAILED`
- `amount_cents`, `currency`, `provider_txn_id`

### Ticket
Biglietto numerato che abilita l ingresso al pool. Vincolato a:
- un `pool_id`
- un `user_id`
- un `purchase_id` confermato
- `ticket_num` progressivo (vincolo univoco per pool)

### User
Modello di utilita (`app_user`) usato per associare acquisti e ticket a un utente autenticato (integrazione auth demandata a Supabase / JWT).

---

## Flow Ticket & Purchase

1. **Purchase**: il client crea/aggiorna un acquisto via `POST /api/v1/purchases` specificando importo, tipo e id transazione del provider. Il servizio salva lo stato iniziale (`PENDING`).
2. **Conferma**: quando il provider segnala l esito positivo, l acquisto viene marcato `CONFIRMED` tramite `PUT /api/v1/purchases/{id}`.
3. **Redeem ticket**: il frontend invoca `POST /api/v1/tickets` con `pool_id`, `user_id` e `purchase_id`.
   - Il servizio carica il pool e verifica che sia `OPEN` e non saturo.
   - Controlla che l acquisto appartenga allo stesso utente, che il `type` sia `ENTRY`, lo `status` `CONFIRMED` e che non sia gia stato redento.
   - Genera `ticket_num = tickets_sold + 1`, inserisce il ticket e aggiorna `tickets_sold`.
   - Se la soglia `tickets_required` viene raggiunta, lo stato del pool passa a `FULL`.
4. **Ulteriori azioni**: a pool pieno puoi eseguire estrazioni, notifiche Realtime o generare vincitori tramite job dedicati.

Questa catena garantisce che ogni ticket derivi da un acquisto valido e non possa essere riutilizzato, prevenendo frodi e disallineamenti contabili.

---

## Endpoint disponibili (v1)

| Risorsa | Path base | Operazioni principali |
|---------|-----------|-----------------------|
| Prize | `/api/v1/prizes` | CRUD completo su premi |
| Pool | `/api/v1/pools` | CRUD + conteggio ticket |
| Purchase | `/api/v1/purchases` | Creazione, update stato, lista utente |
| Ticket | `/api/v1/tickets` | Creazione ticket da purchase, CRUD |
| User | `/api/v1/users` | Utility per gestione utenti (seed/test) |

Autenticazione e autorizzazione sono demandate agli header gestiti in `auth.py`; modifica gli helper per integrarti con Supabase o identity provider custom.

---

## Prossimi step suggeriti

- Automatizzare il sorteggio dei pool completi e notificare i vincitori.
- Gestire pagamenti multipli (`BOOST`, `RETRY`) con logiche dedicate nel servizio ticket.
- Abilitare webhooks da provider pagamento per aggiornare lo stato `Purchase.status`.
- Aggiungere test end-to-end per assicurare la catena purchase → ticket.

Hai domande o trovi incongruenze? Apri una issue o contatta il team backend.
