# Tickup Frontend - Flutter 3.3+ Modern Architecture
*(solo lato app; il backend FastAPI e documentato a parte)*

> Tickup e un arcade skill-based in cui gli utenti partecipano a mini giochi e pool a premi. Questo README ti guida nel setup del frontend Flutter e nel workflow quotidiano.

---

## Stack tecnologico

| Layer | Tecnologie principali | Note |
|-------|-----------------------|------|
| App shell | Flutter 3.3+, Material 3 | Supporto light/dark theme e web/mobile |
| State management | Flutter Riverpod 2.6 | ProviderScope con observer custom (`RiverpodLogger`) |
| Routing | go_router 13 | Navigazione dichiarativa con shell e guard |
| Networking | Dio 5, Supabase Flutter | REST API + sessione auth con refresh token |
| Realtime | Supabase Realtime | Aggiornamenti live su tabelle (es. pools) |
| Mini games | Flame + widget Flutter | Integra motore arcade con scene custom |

---

## Prerequisiti

| Strumento | Versione minima | Note |
|-----------|-----------------|------|
| Flutter SDK | 3.3 (channel stable) | Verifica con `flutter --version` |
| Dart | 3.3 | Incluso nel bundle Flutter |
| Android SDK | API 30+ | Target SDK 34 configurato nel progetto |
| Android NDK | 27.0.12077973 | Imposta `ndkVersion` in `android/app/build.gradle` |
| iOS | 12.0+ | Richiede Xcode per il build |
| Python 3 | 3.10+ | Necessario per `make serve-web` |
| qrencode (opzionale) | latest | Per generare il QR code locale |

---

## Setup rapido

1. Clona il repository e accedi alla root (questo README copre `frontend/`).
2. Installa dipendenze di backend e frontend con:
   ```bash
   make install
   ```
3. Prepara i file environment del backend (`backend/.env`) se usi `make api`.
4. Avvia backend e frontend web in due terminal:
   ```bash
   make api
   make web
   ```
   Il target `make web` abilita automaticamente il supporto web e espone l'app su `http://0.0.0.0:8080`.
5. Per build e deploy web:
   ```bash
   make build-web
   make serve-web   # server statico per verificare la build
   ```
6. Per corse mobili lancia un emulatore registrato (`EMULATOR_ID`) e usa `make android`.

> Suggerimento: puoi sovrascrivere le variabili del Makefile al volo, ad esempio `make FRONTEND_PORT=3001 web` o `make BACKEND_PORT=9000 api`.

---

## Workflow con Makefile

| Comando | Cosa fa | Dipendenze |
|---------|---------|------------|
| `make help` | Mostra la lista dei target disponibili | - |
| `make install` | `poetry install` nel backend e `flutter pub get` nel frontend | Poetry, Flutter |
| `make api` | Avvia FastAPI con uvicorn su `0.0.0.0:8000` (configurabile) | File `.env` del backend |
| `make web` | Avvia Flutter web server su `0.0.0.0:8080` | Dispositivo web abilitato |
| `make build-web` | Esegue `flutter build web` | Directory `frontend/build/web` |
| `make serve-web` | Pubblica la cartella `build/web` via `python -m http.server` | Python 3 |
| `make android` | Avvia un emulatore Android (se presente) e lancia `flutter run` | SDK Android, emulatore definito |
| `make qr` | Genera `qrcode.png` con l'URL locale del frontend web | `qrencode` installato |
| `make kill-ports` | Libera le porte del backend e frontend (richiede `lsof`) | lsof |
| `make ip` | Stampa l'indirizzo IP locale da condividere con i device | hostname |

Variabili globali utili: `BACKEND_DIR`, `FRONTEND_DIR`, `BACKEND_PORT`, `FRONTEND_PORT`, `ENV_FILE`, `EMULATOR_ID`. Tutte possono essere ridefinite nel comando `make` senza modificare il file.

---

## Configurazione ambiente

L'app legge i parametri principali tramite `--dart-define` esposti in `EnvConfig`:

```dart
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const bool isDevelopment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development') == 'development';
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
}
```

Durante lo sviluppo puoi usare:

```bash
flutter run -d chrome \
  --dart-define SUPABASE_URL=https://<id>.supabase.co \
  --dart-define SUPABASE_ANON_KEY=<anon-key> \
  --dart-define ENVIRONMENT=development
```

Sul web, `DioClient` ricava automaticamente host e schema della pagina aperta e punta il backend alla porta `8000`. Su emulatori Android usa `10.0.2.2`, su iOS/desktop `localhost`.

---

## Struttura del codice (`frontend/lib`)

```
lib/
├── app.dart                  # MaterialApp.router con tema dinamico
├── main.dart                 # Bootstrap, Supabase init e ProviderScope
├── core/
│   ├── config/
│   │   └── env_config.dart   # Gestione dei dart-define
│   ├── network/
│   │   ├── auth_service.dart # Access token e refresh tramite Supabase
│   │   └── dio_client.dart   # Client HTTP con interceptor JWT
│   ├── realtime/
│   │   └── supabase_realtime.dart # Abbonamenti alle tabelle
│   ├── theme/
│   │   └── app_theme.dart    # Palette Material 3
│   └── utils/
│       └── logger.dart       # Observer per Riverpod e logging centralizzato
├── data/
│   ├── models/
│   │   ├── prize.dart
│   │   └── raffle_pool.dart
│   ├── remote/
│   │   ├── prize_remote_datasource.dart
│   │   └── raffle_remote_datasource.dart
│   └── repositories/
│       ├── price_repository.dart   # Wrapper REST premi
│       └── raffle_repository.dart  # Wrapper REST pool
├── presentation/
│   ├── routing/
│   │   ├── app_route.dart     # Costanti e path
│   │   └── app_router.dart    # GoRouter + ShellRoute
│   ├── widgets/
│   │   ├── bottom_nav_bar.dart
│   │   ├── pool_card.dart
│   │   └── prize_card.dart
│   └── pages/
│       ├── shell/main_shell.dart
│       ├── error/error_screen.dart
│       ├── games/game_launcher.dart
│       ├── games/game_runner.dart
│       ├── home/home_screen.dart
│       ├── profile/profile_screen.dart
│       ├── prize/
│       │   ├── prize_page.dart
│       │   ├── my_prizes_page.dart
│       │   └── prize_details_page.dart
│       └── pool/
│           ├── pool_create_page.dart
│           ├── pool_details_page.dart
│           └── my_pools_page.dart
├── presentation/features/
│   ├── pool/pool_provider.dart
│   └── prize/prize_provider.dart
└── providers/
    ├── navigation_provider.dart
    └── theme_provider.dart
```

La directory `presentation/features/` ospita la logica di stato per dominio (es. `PrizeProvider`), separata dalle pagine UI contenute in `presentation/pages/`.

---

## Architettura e flussi

### Flow premi (CRUD)
```
presentation/pages/prize/prize_page.dart
  -> presentation/features/prize/prize_provider.dart
  -> data/repositories/price_repository.dart
  -> data/remote/prize_remote_datasource.dart
  -> core/network/dio_client.dart
  -> FastAPI (auth tramite Supabase)
```

### Flow pool e realtime
```
presentation/pages/pool/pool_details_page.dart
  -> presentation/features/pool/pool_provider.dart
  -> data/repositories/raffle_repository.dart
  -> data/remote/raffle_remote_datasource.dart
  -> core/realtime/supabase_realtime.dart (aggiornamenti live)
```

- Il routing principale vive in `app_router.dart` con una `ShellRoute` che mostra `MainShell` e il bottom navigation.
- I providers globali (`theme_provider`, `navigation_provider`) risiedono in `lib/providers` per non mescolarsi con lo stato di dominio.
- `Logger` implementa un observer Riverpod per loggare transizioni di stato durante lo sviluppo.

---

## Testing e quality

```bash
flutter analyze            # lint
flutter test               # unit/widget test folder
flutter test integration_test/   # se presenti integrazioni
```

Nel caso tu aggiunga nuovi mini giochi con Flame, considera testare la logica pura in `test/` e mantenere la grafica isolata.

---

## Troubleshooting

| Problema | Soluzione |
|----------|-----------|
| Errore 401 continuo | Verifica che `AuthService.refreshToken` completi con sessione valida Supabase |
| Il backend non e raggiungibile dal web | Assicurati che `make api` giri su `0.0.0.0` e che `DioClient` abbia la porta corretta |
| L app web non risponde col device | Usa `make qr` e collega il device alla stessa rete, oppure esegui `make ip` per condividere l IP |
| NDK mismatch su Android | Controlla `ndkVersion` in Gradle e reinstalla dal SDK Manager |
| `flutter run -d web-server` fallisce | Esegui `flutter config --enable-web` (già gestito da `make web`) |

---

## Contributing

1. Crea un branch feature: `git checkout -b feature/nome-funzionalita`.
2. Esegui lint e test prima di committare.
3. Apri una pull request descrivendo modifiche e passi per riprodurre.

---

## Supporto e note

- Consulta la documentazione ufficiale di Flutter, Riverpod e GoRouter per approfondimenti.
- Per problemi collegati al backend FastAPI fai riferimento alla documentazione nella cartella `backend/`.

Buon divertimento con Tickup! :)
