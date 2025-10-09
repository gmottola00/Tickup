# Tickup Backend

Backend REST di Tickup costruito con **FastAPI**, **SQLAlchemy async** e **PostgreSQL/Supabase**.  
Gestisce il cuore della piattaforma: premi, pool di biglietti, ticket, acquisti, likes e componenti wallet.

---

## Stack & principali dipendenze

- **FastAPI** per routing e OpenAPI (Swagger su `/docs`, ReDoc su `/redoc`).
- **SQLAlchemy 2 async** + **Alembic** per ORM e migrazioni.
- **Poetry** per la gestione del virtualenv e delle dipendenze.
- **Supabase** come identity provider (JWT), storage e database managed.

---

## Requisiti

| Tool      | Versione | Note                                          |
|-----------|----------|-----------------------------------------------|
| Python    | ≥ 3.10   | Utilizza la sintassi `match`, type hints 3.10 |
| Poetry    | ≥ 1.6    | Consigliato usare `pipx install poetry`       |
| PostgreSQL| 13+      | In locale o via Supabase                      |
| Make      | opzionale| Consente di usare i target condivisi          |

---

## Prime operazioni

1. **Installazione dipendenze**
   ```bash
   cd backend
   poetry install
   ```
   In alternativa dalla root del monorepo:
   ```bash
   make install
   ```

2. **Configura l’ambiente**  
   Crea `backend/.env` con le variabili necessarie:
   ```dotenv
   DATABASE_URL=postgresql+asyncpg://postgres:password@host:5432/postgres
   SUPABASE_URL=https://<project>.supabase.co
   SUPABASE_KEY=<service-role-key>
   SUPABASE_JWT=<jwt-secret>
   ```
   Altri parametri opzionali sono definiti in `app/core/config.py`.

3. **Esegui le migrazioni**
   ```bash
   cd backend
   poetry run alembic upgrade head
   ```

4. **Avvia il server**
   ```bash
   make api  # dalla root del monorepo
   ```
   oppure
   ```bash
   poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file backend/.env --reload
   ```

Swagger UI: <http://localhost:8000/docs>  
ReDoc: <http://localhost:8000/redoc>

---

## Struttura del progetto

```
app/
├── main.py                     # Crea FastAPI app, CORS, include router v1
├── core/                       # Config, security hook, logging
├── api/
│   └── v1/
│       ├── auth.py             # Recupero user id dai token Supabase/JWT
│       ├── deps.py             # Dipendenze comuni (sessione DB, ecc.)
│       └── routers/            # Endpoints versionati
│           ├── pool.py
│           ├── prize.py
│           ├── purchase.py
│           ├── ticket.py
│           ├── user.py
│           └── wallet.py
├── services/                   # Business logic atomica per dominio
├── models/                     # SQLAlchemy models (Pool, Prize, Like, Wallet…)
├── schemas/                    # Schemi Pydantic (request/response)
└── db/                         # Engine async, base declarative, migrazioni Alembic

tests/                          # pytest (unit + integrazione)
pyproject.toml                  # Dipendenze Poetry
alembic.ini                     # Config Alembic
```

---

## Funzionalità principali

### Premi & immagini

- CRUD premi (`/api/v1/prizes`).
- Galleria associata (`/api/v1/prizes/{id}/images`): upload metadata, definizione cover, riordino, delete.
- Integrazione con Supabase Storage per i file reali (il backend salva solo metadati e path pubblicabili).

### Pool & likes

- CRUD pool (`/api/v1/pools`), listing globale (`/all_pools`) e per utente (`/my`).
- Like/unlike idempotenti con contatore consistente (`/pools/{id}/like`).
- Endpoint `/pools/{id}/likes` ritorna `{ likes, liked_by_me }` calcolando lo stato per l’utente corrente.

### Ticket & purchase

- Registro acquisti (`/purchases`) con tipologie (`ENTRY`, `BOOST`, `RETRY`) e stati (`PENDING`, `CONFIRMED`, `FAILED`).
- Emissione ticket (`/pools/{id}/tickets`) valida l’esistenza di un acquisto confermato, assegna numero progressivo, aggiorna `tickets_sold` e imposta lo stato `FULL` quando la soglia è raggiunta.

### Wallet (in sviluppo)

- Modelli per `wallet_account`, `wallet_ledger`, `wallet_topup_request`, `wallet_hold`.
- Le movimentazioni vengono registrate in modalità append-only; il saldo cache (`wallet_account.balance_cents`) è aggiornato da trigger/transazioni per letture veloci.

---

## Eseguire i test

```bash
cd backend
poetry run pytest
```

Consigli:
- Usa database dedicato per i test (configurabile via variabili d’ambiente).
- Integra `pytest --disable-warnings -q` in CI per feedback rapidi.

---

## Utility & comandi

| Comando                              | Descrizione                                    |
|--------------------------------------|------------------------------------------------|
| `poetry shell`                       | Attiva virtualenv                              |
| `poetry run alembic revision ...`    | Genera nuova migration                         |
| `poetry run alembic upgrade head`    | Applica l’ultima migration                     |
| `poetry run uvicorn app.main:app`    | Avvio manuale API                              |
| `make api` (root)                    | Avvio con parametri da Makefile                |
| `make kill-ports` (root)             | Libera porte 8000/8080                         |

---

## Convenzioni & suggerimenti

- Mantieni separata la logica di dominio nelle `services/`. I router devono delegare e gestire solo validazione/risposte HTTP.
- Usa le `schemas/` per serializzazione consistente. Se aggiungi campi ai modelli, aggiorna anche i DTO equivalenti.
- Ogni modifica al DB → crea migration Alembic atomica con descrizione chiara.
- Le eccezioni domain-specific convertono in `HTTPException` con messaggi pensati per il client.
- Aggiorna la documentazione qui (sezione funzionalità/API) quando introduci nuove rotte o flussi.

---

## Prossimi passi suggeriti

- Automazione sorteggio vincitori (cron job o event handler).
- Webhook provider pagamento per aggiornare `Purchase.status`.
- Endpoints aggregati per statistiche pool (es. top liked, pool completati).
- Test end‑to‑end che coprano la catena `purchase → ticket → pool FULL`.

Per domande o contributi apri una issue o contatta il team backend.
