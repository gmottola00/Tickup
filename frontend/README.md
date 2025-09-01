# SkillWin Frontend – Flutter 3.22+ Modern Architecture
*(solo lato app, FastAPI non è trattato qui)*

> Mini‑arcade **skill‑based** dove l'utente gioca a micro‑giochi per vincere premi reali.

---

## ⚙️ Stack Tecnologico

| Layer | Tech & Package Principali | Note |
|-------|--------------------------|------|
| **State Management** | Riverpod 2.4+ | Provider pattern con sintassi classica |
| **Routing** | GoRouter 13+ | Named routes, guards, deep linking |
| **Backend** | Supabase | Auth, Realtime, Database |
| **HTTP Client** | Dio 5+ | REST API con interceptors |
| **UI Components** | Material 3 | Design system moderno con dark mode |
| **Mini‑games** | Flutter widgets puri | Ogni gioco implementa `GameInterface` |

---

## 🚀 Prerequisiti

| Global | Versione Minima | Note |
|--------|-----------------|------|
| **Flutter** | 3.22+ | Stable channel |
| **Dart** | 3.4+ | Null safety |
| **Android SDK** | API 30+ | Target SDK 34 |
| **Android NDK** | **27.0.12077973** | Configurazione obbligatoria |
| **iOS** | 12.0+ | Per deployment iOS |

---

## 🏗️ Nuova Architettura

### Pattern & Principi
- **Clean Architecture**: Separazione netta tra layers
- **Repository Pattern**: Astrazione delle data sources
- **Provider Pattern**: State management reattivo
- **SOLID Principles**: Codice manutenibile e testabile

### Flusso Dati
```
UI Layer → State (Riverpod) → Repository → Data Source → API/Database
    ↑                              ↓
    └──────── Response ────────────┘
```

---

## 🗂️ Struttura del Progetto

```
lib/
├── app.dart                       # MaterialApp.router configuration
├── main.dart                      # Entry point + inizializzazione
│
├── core/                          # Layer Core - Utilities condivise
│   ├── config/
│   │   └── env_config.dart        # Variabili ambiente (dev/prod)
│   ├── constants/
│   │   └── app_constants.dart     # Costanti globali
│   ├── network/
│   │   ├── dio_client.dart        # HTTP client singleton
│   │   └── auth_interceptor.dart  # JWT refresh automatico
│   ├── theme/
│   │   └── app_theme.dart         # Material 3 theme definition
│   ├── utils/
│   │   ├── logger.dart            # Logging centralizzato
│   │   └── validators.dart        # Form validators
│   └── game_engine/
│       ├── game_engine.dart       # Motore di gioco
│       ├── game_interface.dart    # Interfaccia comune giochi
│       └── game_result.dart       # Risultati partita
│
├── data/                          # Layer Data - Gestione dati
│   ├── models/                    # Data models (JSON serializable)
│   │   ├── user.dart
│   │   ├── prize.dart
│   │   ├── game.dart
│   │   └── leaderboard_entry.dart
│   ├── datasources/
│   │   ├── remote/                # API calls
│   │   │   ├── auth_remote.dart
│   │   │   ├── prize_remote.dart
│   │   │   └── game_remote.dart
│   │   └── local/                 # Cache locale
│   │       └── preferences.dart
│   └── repositories/              # Repository implementations
│       ├── auth_repository.dart
│       ├── prize_repository.dart
│       └── game_repository.dart
│
├── domain/                        # Layer Domain (opzionale per progetti grandi)
│   ├── entities/                 # Business entities
│   └── usecases/                 # Business logic
│
├── presentation/                  # Layer Presentation - UI
│   ├── routing/
│   │   ├── app_router.dart       # GoRouter configuration
│   │   └── app_route.dart        # Route constants
│   ├── pages/                    # Schermate principali
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── shell/
│   │   │   └── main_shell.dart   # Shell con bottom nav
│   │   ├── games/
│   │   │   ├── game_launcher.dart
│   │   │   ├── game_runner.dart
│   │   │   └── games/            # Mini-giochi
│   │   │       ├── memory/
│   │   │       ├── puzzle/
│   │   │       └── reaction/
│   │   ├── prizes/
│   │   │   ├── prizes_screen.dart
│   │   │   └── prize_details_screen.dart
│   │   ├── leaderboard/
│   │   │   └── leaderboard_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── profile_edit_screen.dart
│   │   └── error/
│   │       └── error_screen.dart
│   └── widgets/                  # Widget riutilizzabili
│       ├── common/
│       │   ├── loading_widget.dart
│       │   └── error_widget.dart
│       └── bottom_navigation/
│           └── modern_bottom_navigation.dart
│
└── providers/                     # State Management
    ├── auth_provider.dart         # Gestione autenticazione
    ├── user_provider.dart         # Dati utente
    ├── game_provider.dart         # Stato giochi
    ├── prize_provider.dart        # Gestione premi
    ├── navigation_provider.dart   # Stato navigazione
    └── theme_provider.dart        # Tema app
```

---

## 🎯 Flusso Architetturale Completo

### Esempio: Prize Flow
```
PrizesScreen 
    ↓ (watch)
PrizeProvider (Riverpod)
    ↓ (calls)
PrizeRepository
    ↓ (uses)
PrizeRemoteDataSource
    ↓ (http)
DioClient → Supabase/FastAPI
```

### Navigation Flow
```
GoRouter (Provider)
    ├── Splash Screen (initial)
    ├── Auth Routes (no shell)
    │   ├── Login
    │   └── Register
    ├── Main Shell (with bottom nav)
    │   ├── Games Tab
    │   ├── Prizes Tab
    │   ├── Leaderboard Tab
    │   └── Profile Tab
    └── Fullscreen Routes (no shell)
        └── Game Runner
```

---

## 🚦 Setup Completo

### 1. **Clona e Installa**
```bash
git clone <repo-url>
cd skillwin-frontend
flutter pub get
```

### 2. **Configura Piattaforme**
```bash
flutter create --platforms=android,ios,web .
```

### 3. **Android NDK Setup**
In `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    ndkVersion = "27.0.12077973"
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 4. **Configura Environment Variables**
Crea `.env` nella root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
BACKEND_URL=http://localhost:8000/api/v1
ENVIRONMENT=development
```

### 5. **Supabase Setup**
```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

### 6. **Run Development**
```bash
# Android Emulator
flutter run

# iOS Simulator
flutter run -d iPhone

# Web (Chrome)
flutter run -d chrome

# Con hot reload
flutter run --hot
```

---

## 🎮 Aggiungere un Mini-Gioco

### 1. **Crea la struttura del gioco**
```dart
// lib/presentation/pages/games/games/nuovo_gioco/nuovo_gioco.dart
class NuovoGioco extends ConsumerStatefulWidget implements GameInterface {
  @override
  ConsumerState<NuovoGioco> createState() => _NuovoGiocoState();
  
  @override
  Future<GameResult> startGame() async {
    // Logica del gioco
  }
}
```

### 2. **Aggiungi il Provider (opzionale)**
```dart
// lib/providers/games/nuovo_gioco_provider.dart
final nuovoGiocoProvider = StateNotifierProvider<NuovoGiocoNotifier, GameState>((ref) {
  return NuovoGiocoNotifier();
});
```

### 3. **Registra nel Game Launcher**
```dart
// lib/presentation/pages/games/game_launcher.dart
final games = [
  GameConfig(
    id: 'nuovo-gioco',
    name: 'Nuovo Gioco',
    icon: Icons.gamepad,
    widget: NuovoGioco(),
  ),
  // altri giochi...
];
```

---

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## 📱 Build & Deploy

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Debug IPA
flutter build ios --debug

# Release IPA (App Store)
flutter build ios --release
```

### Web
```bash
# Build web
flutter build web --release

# Deploy su Firebase Hosting
firebase deploy --only hosting
```

---

## 🔧 Troubleshooting Comune

| Problema | Soluzione |
|----------|-----------|
| **NDK Version Mismatch** | Installa NDK 27.0.12077973 da Android Studio SDK Manager |
| **Riverpod Not Working** | Assicurati di wrappare l'app con `ProviderScope` |
| **GoRouter 404** | Verifica che tutte le route siano registrate in `app_router.dart` |
| **Supabase Auth Loop** | Controlla `RouterNotifier` e auth state listeners |
| **Bottom Nav Non Visibile** | Verifica che la route sia dentro `ShellRoute` |
| **Build iOS Fallisce** | Esegui `cd ios && pod install` |
| **Web CORS Issues** | Configura CORS nel backend o usa proxy |

---

## 📚 Documentazione Utile

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Material 3 Design](https://m3.material.io/)

---

## 🚀 Roadmap

### Completato ✅
- [x] Architettura pulita con layer separation
- [x] GoRouter con deep linking
- [x] Riverpod state management
- [x] Modern bottom navigation
- [x] Dark mode support
- [x] Splash screen animata
- [x] Shell con auto-hide navigation

### In Progress 🔄
- [ ] Implementazione mini-giochi
- [ ] Sistema premi completo
- [ ] Leaderboard realtime
- [ ] Profile customization

### Prossimi Step 📋
- [ ] Push notifications
- [ ] Social login (Google, Apple)
- [ ] In-app purchases
- [ ] Achievements system
- [ ] Multiplayer support
- [ ] Analytics integration
- [ ] Crash reporting
- [ ] CI/CD pipeline

---

## 👥 Contributing

1. Fork il repository
2. Crea un feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit le modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

---

## 📄 License

Questo progetto è sotto licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.

---

## 🤝 Support

Per supporto, apri una issue su GitHub o contatta il team di sviluppo.

---

**Buon divertimento con SkillWin Arcade!** 🎮🏆