# Tickup Frontend (Flutter)

Applicazione Flutter (web, Android, iOS) per la piattaforma Tickup.  
Gestisce autenticazione Supabase, listing premi/pool, likes, acquisti ticket e mini‑giochi arcade.

---

## Stack principale

| Layer          | Tecnologie / Pacchetti principali                                          |
|----------------|-----------------------------------------------------------------------------|
| Framework      | Flutter 3.3+ (Material 3, supporto web/mobile)                              |
| State manager  | Riverpod 2 (provider, AsyncNotifier, StateNotifier) con observer custom     |
| Routing        | go_router 13 con `ShellRoute` per la bottom navigation                      |
| Networking     | Dio 5 + Supabase Flutter (auth, storage, realtime)                          |
| Storage        | Supabase Storage: cover immagini premi/pool, URL pubblici generati in app   |
| Giochi         | Flame + integrazione Unity via `flutter_unity_widget`                       |

---

## Requisiti

| Strumento        | Versione | Note                                                        |
|------------------|----------|-------------------------------------------------------------|
| Flutter SDK      | ≥ 3.3    | `flutter doctor` deve risultare “green”                     |
| Dart             | ≥ 3.3    | Incluso nel bundle Flutter                                   |
| Android SDK/NDK  | API 30+ / NDK 27.0.12077973 | Necessari per build Android             |
| Xcode (macOS)    | 14+      | Per build/test iOS                                          |
| Python 3         | ≥ 3.10   | Usato da `make serve-web`                                    |
| qrencode         | opzionale| Per il target `make qr`                                      |

---

## Setup rapido

1. **Installazione dipendenze**
   ```bash
   make install        # dalla root del monorepo
   ```

2. **Configura Supabase e backend**
   - Avere un backend attivo (`make api`).
   - Prepara i `--dart-define` necessari (vedi sezione [Ambiente](#ambiente-e-config)).

3. **Avviare in sviluppo**
   ```bash
   make web            # abilita Web, avvia web-server su 0.0.0.0:8080
   ```

4. **Altre modalità**
   ```bash
   make build-web      # build statica in build/web
   make serve-web      # miniserver HTTP per build web
   make android        # avvia emulatore (EMULATOR_ID) e flutter run
   make qr             # generazione qrcode.png con URL locale
   ```

Puoi ridefinire le variabili del Makefile al volo:
```
make FRONTEND_PORT=3001 web
make EMULATOR_ID="Pixel_7_API_34" android
```

---

## Ambiente e config

La classe `EnvConfig` legge i valori da `--dart-define`:

```bash
flutter run -d chrome \
  --dart-define SUPABASE_URL=https://<id>.supabase.co \
  --dart-define SUPABASE_ANON_KEY=<anon-key> \
  --dart-define ENVIRONMENT=development \
  --dart-define APP_VERSION=1.0.0
```

Altre chiavi utili:

- `BACKEND_PORT`: se devi puntare a una porta differente (Dio calcola host/porta in automatico per il web).
- `SUPABASE_STORAGE_BUCKET`: opzionale; di default vengono usati i nomi presenti nei metadati (`bucket`).

Per Android emulator il client usa `10.0.2.2:8000`, su iOS/desktop `localhost:8000`.

---

## Struttura del codice (`lib/`)

```
lib/
├── app.dart                        # MaterialApp.router + tema dinamico
├── main.dart                       # Bootstrap, Supabase init, ProviderScope
├── core/
│   ├── config/env_config.dart      # Gestione dart-define
│   ├── network/                    # DioClient, AuthService (token refresh supabase)
│   ├── realtime/                   # Canali realtime Supabase
│   ├── theme/app_theme.dart        # Palette Material 3
│   └── utils/logger.dart           # Observer Riverpod in debug
├── data/
│   ├── models/                     # Prize, Pool, LikeStatus, Purchase, ecc.
│   ├── remote/                     # Datasource REST (Dio)
│   └── repositories/               # Coordinano datasource + business rules
├── presentation/
│   ├── routing/app_route.dart      # go_router definitions
│   ├── features/                   # Provider Riverpod organizzati per dominio
│   ├── pages/                      # Screens (home, pool, prize, wallet…)
│   └── widgets/                    # UI riutilizzabili (card, skeleton, grid)
└── providers/                      # Theme / navigation provider globali
```

---

## Caratteristiche

- **PoolCard & PrizeCard**: recuperano dinamicamente le immagini di copertina da Supabase Storage (galleria `prizeImagesProvider`), con fallback a `prize.imageUrl` e placeholder coerente.
- **Shell navigation**: `MainShell` combina bottom navigation e sub‑route con persistenza stato per ogni tab.
- **Mini-giochi**: `presentation/pages/game` integra Flame e Unity; la configurazione Unity è opzionale e isolata.
- **Realtime**: `SupabaseRealtime` (quando attivato) sincronizza update su pool/ticket senza refresh manuale.

---

## Testing & quality

```bash
cd frontend
flutter analyze
flutter test
```

Per test d’integrazione:
```bash
flutter test integration_test
```

Consigli:
- Abilita `flutter format` pre-commit.
- Usa `flutter run --profile` per analizzare prestazioni dei mini‑giochi.

---

## Troubleshooting

| Problema                                   | Soluzione                                                                 |
|--------------------------------------------|---------------------------------------------------------------------------|
| Il web non raggiunge il backend            | Assicurati che `make api` giri su `0.0.0.0` e che la porta combaci (8000).|
| Like/griglia non aggiorna                  | Verifica Supabase sessione attiva; puoi invalidare i provider con pull-to-refresh.|
| Cover immagini non visibili                | Controlla che i metadati `bucket`/`storage_path` esistano e siano pubblici.|
| Errore NDK durante build Android           | Allinea `ndkVersion` con quanto indicato nel README e reinstalla dal SDK Manager.|
| Unity crash                                | Verifica `UnityExport/` presente e `MainActivity` che estende `FlutterUnityActivity`.|

---

## Contributi

1. Crea un branch: `git checkout -b feature/nome-funzionalita`.
2. Implementa, esegui `flutter analyze` e `flutter test`.
3. Aggiorna la documentazione se necessario.
4. Apri una Pull Request dettagliando modifiche, test eseguiti e eventuali note di QA.

Per ulteriori dettagli o best practice consulta il README principale o contatta il team frontend.
