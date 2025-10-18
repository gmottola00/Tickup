# Tickup – Game Architecture & Pixel Adventure Integration

Questo documento riassume lo stato attuale dell’integrazione giochi nel frontend Flutter
e delinea le linee guida per evolvere Pixel Adventure con timer, punteggi e
persistenza lato backend. È pensato come riferimento per designer, dev front/back e
per la definizione del data model legato ai premi/pool.

---

## 1. Topologia del modulo giochi

```
frontend/
├── lib/
│   ├── pixel_adventure.dart          # FlameGame configurabile (livelli, punteggio, timer)
│   ├── components/                   # Sprite, entità e logiche di collisione
│   └── presentation/pages/games/
│       ├── game_launcher.dart        # Lista giochi
│       ├── game_runner.dart          # Router → menu gioco
│       └── pixel_adventure_menu.dart # Menu livelli Pixel Adventure
└── assets/tiles/                     # Mappe TMX, tileset, asset grafici
```

- **GameLauncher** mostra tutti i mini‑giochi. Selezionando *Pixel Adventure* si apre
  `PixelAdventureMenuPage`.
- **PixelAdventureMenuPage** elenca i livelli disponibili (TMX) e avvia il gioco con
  l’indice selezionato.
- **PixelAdventure (FlameGame)** carica asset, gestisce il player, la camera
  a risoluzione fissa e coordina HUD/joystick.
- I componenti (player, frutti, nemici, checkpoint, ecc.) utilizzano le API Flame
  1.32 (`HasGameReference`, `Future<void> onLoad`, collisioni aggiornate).

---

## 2. Livelli TMX

- Cartella: `frontend/assets/tiles`
- Nomenclatura: `Level-01.tmx`, `Level-02.tmx`, …
- Ogni mappa deve includere almeno i layer:
  - `Background` (tile layer, proprietà opzionale `BackgroundColor`)
  - `Spawnpoints` (objectgroup con oggetti `Player`, `Fruit`, `Checkpoint`, `Chicken`, `Saw`)
  - `Collisions` (objectgroup con rettangoli solidi e `type="Platform"` per piattaforme passanti)

> **Nota:** Level‑02 è stato allineato a Level‑01 aggiungendo il layer `Collisions` per
> evitare che il player cada nel vuoto.

---

## 3. Timer e punteggio (design)

### 3.1 Timer
1. Aggiungere in `PixelAdventure` un campo `double remainingTime` (es. 120.0 secondi).
2. Aggiornare `update(dt)` sottraendo `dt`. Quando `remainingTime <= 0`:
   - Fermare input (`player.horizontalMovement = 0`, `player.hasJumped = false`)
   - Mostrare overlay “Tempo scaduto”
   - Invocare callback verso il menu (`onGameOver`) per registrare la sessione.
3. Usare un `TimerComponent` o un semplice `bool isGameOver` + `remainingTime = max(0, remainingTime - dt)` per evitare valori negativi.

### 3.2 Punteggio
1. Introdurre `int score` nel game e metodo `addScore(int delta)`.
2. Nei componenti:
   - `Fruit.collidedWithPlayer()` → `gameRef.addScore(fruitValue);`
   - `Chicken.collidedWithPlayer()` → se il player lo stompa: `addScore(enemyKillValue);`
3. Visualizzare punteggio e timer in un overlay HUD:
   - Creare `ValueNotifier<ScoreState>` o usare Riverpod overlay.
   - Registrare overlay nel costruttore di `GameWidget`.

### 3.3 Fine partita
Workflow consigliato:
1. `PixelAdventure` chiama `widget.onSessionFinished(SessionResult result)`.
2. Il menu intercetta l’evento e mostra una dialog (score, tempo residuo, azioni):
   - *Rigioca livello*
   - *Scegli un altro livello*
   - *Invia punteggio al pool* (se integrato)

---

## 4. Persistenza & API

Obiettivo: consentire ai player di partecipare a un *pool* (premio a estrazione) con
una sessione di gioco tracciata.

### 4.1 Schema relazionale suggerito

```
players
----------
id (PK)
user_id (FK -> auth.users Supabase)
nickname
created_at

games
----------
id (PK)
code (es. "pixel_adventure")
title

levels
----------
id (PK)
game_id (FK -> games)
code (es. "Level-01")
display_name
time_limit_seconds
created_at

pools
----------
# già presente nell’app: collega premi, ticket, ecc.

game_sessions
----------
id (PK)
player_id (FK -> players)
pool_id (FK -> pools)
level_id (FK -> levels)
score
time_spent_seconds
outcome (enum: cleared, timeout, aborted)
recorded_at (timestamp)

session_events (opzionale)
----------
id (PK)
session_id (FK -> game_sessions)
event_type (collect, enemy_kill, damage, checkpoint, timeout)
payload JSONB
created_at

leaderboards
----------
id (PK)
pool_id (FK -> pools)
player_id (FK -> players)
best_score
best_time
updated_at

pool_rewards (opzionale)
----------
pool_id (FK -> pools)
threshold_score
reward_id (FK -> rewards)
```

### 4.2 API/Workflow proposto

1. **Avvio partita**
   - Client invia `POST /game-sessions/start` con `{ pool_id, level_id }`.
   - Backend crea record `game_sessions` con `score = 0`, `started_at`.

2. **Aggiornamento runtime (opzionale)**
   - `POST /game-sessions/{id}/events` con lista eventi batch.
   - Utile per audit/anti‑cheat.

3. **Fine partita**
   - `POST /game-sessions/{id}/finish` con `{ score, time_spent_seconds, outcome, events[] }`.
   - Backend valida durata (no sessioni > limite + tolleranza), calcola eventuali ricompense (`pool_rewards`), aggiorna `leaderboards`.

4. **Dashboard/Leaderboard**
   - `GET /pools/{id}/leaderboard` ritorna top N giocatori.
   - `GET /game-sessions?player_id=...` per cronologia sessioni.

---

## 5. Integrazione frontend ↔ backend

1. **Provider GameSession**
   - All’avvio: chiama endpoint start → riceve `sessionId`.
   - Durante la partita: accumula localmente eventi (collect, kill) per eventuale sync.
   - Alla fine: invia `finish`.

2. **HUD & feedback**
   - Mostra punteggio, tempo residuo, `sessionId`.
   - In caso di timeout/uscita forzata notificare il backend con outcome `aborted`.

3. **Gestione premi**
   - Alla chiusura sessione il backend può calcolare ticket ottenuti in base a
     `score` e `time_spent`.
   - L’app mostra quanti ticket/punti sono stati guadagnati e aggiorna il wallet.

---

## 6. TODO roadmap

| Priorità | Attività                                                                 | Stato |
|----------|---------------------------------------------------------------------------|-------|
| Alta     | Implementare `Score HUD` e `Timer` in `PixelAdventure`                    | ☐     |
| Alta     | Creare overlay “Game Over / Timeout” e callback verso il menu            | ☐     |
| Media    | Introdurre servizio GameSession nel frontend (start/finish)              | ☐     |
| Media    | Aggiungere API backend per game sessions + migrazione DB                 | ☐     |
| Bassa    | Persistenza eventi dettagliati (collect/kill) per analytics/anti-cheat   | ☐     |
| Bassa    | Leaderboard pool + premi dinamici                                        | ☐     |

---

## 7. Riferimenti utili

- [Documentazione Flame](https://docs.flame-engine.org/latest/)
- [Flame TimerComponent](https://docs.flame-engine.org/latest/components/timer_component.html)
- [Flame Overlays](https://docs.flame-engine.org/latest/game_widget.html#overlays)
- [Supabase Auth & Storage](https://supabase.com/docs)
- [Riverpod docs](https://riverpod.dev)

Per dubbi o proposte di modifica, aprire una issue o discutere nel canale #game-dev
interno.
