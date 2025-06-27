# Tickup Backend

Backend API per Tickup, costruito con **FastAPI**, **SQLAlchemy** (asyncio), **Alembic** e **Supabase** (PostgreSQL).

---

## 📁 Struttura del Progetto

```
app/
├── main.py                  # Entrypoint FastAPI
├── core/
│   ├── config.py            # Settings (Pydantic BaseSettings)
│   └── security.py          # OAuth2 / JWT placeholders
├── db/
│   ├── base.py              # Base declarative SQLAlchemy
│   ├── session.py           # Engine & session (sync/async)
│   └── migrations/          # Alembic scripts
├── api/
│   └── v1/
│       ├── routers/
│       │   ├── pool.py      # Endpoint CRUD pools
│       │   ├── prize.py     # Endpoint CRUD prizes
│       │   └── ticket.py    # Endpoint CRUD tickets
│       └── deps.py          # Dependency injection (DB, auth, ecc.)
├── models/
│   ├── pool.py              # SQLAlchemy model RafflePool
│   ├── prize.py             # SQLAlchemy model Prize
│   └── ticket.py            # SQLAlchemy model Ticket
├── schemas/
│   ├── pool.py              # Pydantic schemas per Pool
│   ├── prize.py             # Pydantic schemas per Prize
│   └── ticket.py            # Pydantic schemas per Ticket
├── services/
│   ├── pool.py              # Logica CRUD asincrona per Pool
│   ├── prize.py             # Logica CRUD asincrona per Prize
│   └── ticket.py            # Logica CRUD asincrona per Ticket
└── clients/
    └── supabase.py          # Istanza client supabase-py

tests/                       # Unit & integration tests (pytest)
alembic.ini                  # Configurazione Alembic
Dockerfile                   # Containerizzazione
pyproject.toml               # Configurazione Poetry
README.md                    # Questo file
.env                         # Variabili d’ambiente (non versionato)
```

---

## ⚙️ Prerequisiti

- Python 3.10+  
- [Poetry](https://python-poetry.org/)  
- Accesso al database PostgreSQL di Supabase  

---

## 🛠️ Installazione

1. **Clona il repository**  
   ```bash
   git clone https://github.com/tuo-username/tickup-backend.git
   cd tickup-backend
   ```

2. **Crea un file `.env`** in root:
   ```dotenv
   DATABASE_URL=postgresql+asyncpg://postgres:TUAPASSWORD@tuo-progetto.supabase.co:5432/postgres
   SUPABASE_PSW=TUAPASSWORD
   SUPABASE_URL=https://tuo-progetto.supabase.co
   SUPABASE_KEY=YOUR_SUPABASE_KEY
   SUPABASE_JWT=YOUR_JWT_SECRET
   ```

3. **Installa le dipendenze**  
   ```bash
   poetry install
   ```

---

## 🚀 Avvio del Server

```bash
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --env-file .env --reload 
```

- **API** su `http://localhost:8000`  
- **Swagger UI** su `http://localhost:8000/docs`  
- **ReDoc** su `http://localhost:8000/redoc`

---

## 🗄️ Database & Migrazioni (Alembic)

```bash
# Inizializza (prima volta)
poetry run alembic init app/db/migrations

# Configura alembic.ini con:
# sqlalchemy.url = postgresql+asyncpg://...

# Genera e applica migration
poetry run alembic revision --autogenerate -m "Init schema"
poetry run alembic upgrade head
```

---

## 1. Modello dati a livello di DB

### 1.1 `prize`

Rappresenta il premio che sarà “messo in palio” in uno o più pool.

* **`prize_id`** (PK): UUID univoco  
* **`title`**, **`description`**, **`value_cents`**: informazioni sul premio  
* **`image_url`**, **`sponsor`**, **`stock`**: metadati aggiuntivi  
* **`created_at`**: timestamp  

### 1.2 `raffle_pool`

Definisce una “lotteria” o pool di biglietti legata a un singolo premio.

* **`pool_id`** (PK): UUID univoco  
* **`prize_id`** (FK → `prize.prize_id`): premio in palio  
* **`ticket_price_cents`**: costo di un biglietto  
* **`tickets_required`**: soglia di biglietti venduti per far partire il sorteggio  
* **`tickets_sold`**: contatore incrementale di biglietti acquistati  
* **`state`**: `OPEN` │ `FULL` │ `STARTED` │ `CANCELLED`  
* **`created_at`**: timestamp  

**Relazione**: 1 *Prize* → * più *RafflePool*.

### 1.3 `ticket`

Rappresenta il singolo “biglietto” acquistato da un utente per partecipare a un pool.

* **`ticket_id`** (PK): integer autoincrementale  
* **`pool_id`** (FK → `raffle_pool.pool_id`): a quale pool appartiene  
* **`user_id`** (FK → `app_user.user_id`): chi l’ha comprato  
* **`purchase_id`** (FK → `purchase.purchase_id`): dettaglio transazione  
* **`ticket_num`**: numero del biglietto (utile per sorteggi)  
* **`created_at`**: timestamp  

**Relazione**: 1 *RafflePool* → * più *Ticket*.  
**Relazione**: 1 *AppUser* → * più *Ticket*.

---

## 2. Flusso logico di utilizzo

1. **Creazione del premio**

   * Endpoint `POST /api/v1/prizes`  
   * Fornisci titolo, descrizione, valore, ecc.  
   * Restituisce un oggetto **Prize** con `prize_id`.

2. **Apertura di un pool**

   * Endpoint `POST /api/v1/pools`  
   * Passi `prize_id`, `ticket_price_cents`, `tickets_required`.  
   * Viene creato un nuovo **Pool** con `pool_id` e `state = OPEN`.

3. **Vendita di un biglietto**

   * Prima crei una **Purchase** (acquisto) → registra la transazione di pagamento.  
   * Endpoint `POST /api/v1/tickets`  
   ```json
   {
     "pool_id": "<pool_id>",
     "user_id": "<user_id>",
     "purchase_id": "<purchase_id>",
     "ticket_num": 1
   }
   ```
   * Il server:
     1. Verifica che il pool sia `OPEN` e non abbia raggiunto `tickets_required`.  
     2. Inserisce il record **Ticket** e incrementa `tickets_sold`.  
     3. Se `tickets_sold == tickets_required`, aggiorna `state` → `FULL`.

4. **Lettura/Modifica/Cancellazione**

* **Prize**  
  * `GET /api/v1/prizes/{prize_id}`  
  * `PUT /api/v1/prizes/{prize_id}`  
  * `DELETE /api/v1/prizes/{prize_id}`  
* **Pool**  
  * `GET /api/v1/pools/{pool_id}`  
  * `PUT /api/v1/pools/{pool_id}`  
  * `DELETE /api/v1/pools/{pool_id}`  
* **Ticket**  
  * `GET /api/v1/tickets/{ticket_id}`  
  * `PUT /api/v1/tickets/{ticket_id}`  
  * `DELETE /api/v1/tickets/{ticket_id}`  

---

## 3. Esempio di endpoint e comportamento

### 3.1 Creazione Pool

```http
POST /api/v1/pools
Content-Type: application/json

{
  "prize_id": "a1b2c3d4-...-deadbeef",
  "ticket_price_cents": 100,
  "tickets_required": 50
}
```

**Risposta** (201):

```json
{
  "pool_id": "f6e5d4c3-...-feedface",
  "prize_id": "a1b2c3d4-...-deadbeef",
  "ticket_price_cents": 100,
  "tickets_required": 50,
  "tickets_sold": 0,
  "state": "OPEN",
  "created_at": "2025-06-13T…Z"
}
```

### 3.2 Acquisto di un biglietto

```http
POST /api/v1/tickets
Content-Type: application/json

{
  "pool_id": "f6e5d4c3-...-feedface",
  "user_id": "u1234567-…",
  "purchase_id": "p9a8b7c6-…",
  "ticket_num": 1
}
```

* **Server**:
  * Cerca il pool → aggiorna `tickets_sold += 1`.
  * Se `tickets_sold == tickets_required`, passa `state` a `FULL`.
* **Risposta** (201):
```json
{
  "ticket_id": 42,
  "pool_id": "f6e5d4c3-...-feedface",
  "user_id": "u1234567-…",
  "purchase_id": "p9a8b7c6-…",
  "ticket_num": 1,
  "created_at": "2025-06-13T…Z"
}
```

---

## 4. Come evolvere

* **Sorteggio**: quando un pool arriva a `FULL`, puoi avere un endpoint interno (o un cron job) che sceglie un ticket vincente e crea un record in `win`.  
* **Stati aggiuntivi**: `STARTED` per indicare che il sorteggio è in corso, `AWARDED` una volta assegnato il premio.  
* **Webhooks / Realtime**: usa Supabase Realtime per notificare client quando un pool cambia stato.  
* **Paginazione e filtri** negli endpoint `GET /pools` o `GET /tickets`.

---

In sintesi, ogni **Prize** può essere messo in palio da uno o più **Pool**; in ciascun **Pool** gli utenti comprano **Ticket** che li qualificano al sorteggio una volta raggiunta la soglia di biglietti richiesti. Gli endpoint CRUD ti permettono di creare, leggere, aggiornare e cancellare ognuna di queste entità rispettando la logica di dominio sopra descritta.
