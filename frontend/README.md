# SkillWin Frontend – Flutter 3.22+ Boilerplate  
*(solo lato app, FastAPI non è trattato qui)*

> Mini‑arcade **skill‑based** dove l’utente gioca a micro‑giochi per vincere premi reali.

---

## ⚙️ Stack

| Layer | Tech & package principali | Note |
|-------|--------------------------|------|
| **core** | Dio (REST) · Supabase Realtime | Singleton `DioClient` con auto‑refresh JWT |
| **data** | Models JSON · Repository pattern | Mappe 1:1 con le entità FastAPI |
| **presentation** | Flutter 3 · Riverpod 2 · GoRouter | UI modulare + stato reattivo |
| **mini‑games** | Flutter widgets puri | Ogni gioco implementa `GameInterface.startGame()` |

---

## 🚀 Prerequisiti

| Global | Versione minima |
|--------|-----------------|
| **Flutter** | 3.22 |
| **Android SDK** | API 30+ |
| **Android NDK** | **27.0.12077973**<br>_aggiungi in `android/app/build.gradle(.kts)`:_<br>`android { ndkVersion = "27.0.12077973" }` |

---

## 🗂️ Struttura del progetto (frontend)

```
lib/
├─ core/
│   ├─ network/
│   │   ├─ dio_client.dart
│   │   └─ auth_service.dart
│   └─ realtime/
│       └─ realtime_service.dart
│
├─ data/
│   ├─ models/
│   ├─ remote/
│   └─ repositories/
│
├─ presentation/
│   ├─ routing/
│   ├─ state/
│   │   └─ games/
│   └─ pages/
│       ├─ home/
│       ├─ pools/
│       └─ games/
│           └─ reflex_tap/
│
├─ core/game_engine/
│   ├─ game_interface.dart
│   └─ game_result.dart
│
└─ app.dart
main.dart
```

---

## 🏗️ Setup rapido

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Create platforms** (if missing)
   ```bash
   flutter create --platforms=android,ios,web .
   ```

3. **Set NDK version**

   In `android/app/build.gradle(.kts)`:
   ```gradle
   android {
       ndkVersion = "27.0.12077973"
   }
   ```

4. **Configure Supabase**

   ```dart
   // lib/main.dart
   await Supabase.initialize(
     url: 'https://<PROJECT>.supabase.co',
     anonKey: '<ANON-KEY>',
   );
   ```

5. **Backend URL**

   ```dart
   // lib/core/network/dio_client.dart
   baseUrl: 'http://10.0.2.2:8000/api',   // emulator
   ```

6. **Run**
   ```bash
   flutter run          # device selected
   flutter run -d chrome
   ```

---

## 🔧 Architettura

`Page → Provider → Repository → Api → DioClient → FastAPI`

- **core**: servizi condivisi  
- **data**: mapping e sorgenti  
- **presentation**: UI + stato  
- **games**: widget plug‑in

---

## 🎮 Aggiungi un mini‑gioco

1. Crea `presentation/pages/games/nuovo/nuovo_game_page.dart`
2. Stato opzionale in `presentation/state/games/nuovo_logic.dart`
3. Implementa `GameInterface`
4. Registra la rotta in `app_router.dart`

---

## 🚦 Troubleshooting

| Problema | Fix |
|----------|-----|
| 401 loop | controlla `AuthService.refreshToken()` |
| Root isolate | verifica Supabase.init prima di `runApp()` |
| NDK mismatch | assicurati di avere la stessa `ndkVersion` |

---

## 🗒️ Roadmap breve

- [x] GoRouter + deep link  
- [x] JWT interceptor  
- [ ] UI Pools & Ticket  
- [ ] Leaderboard Realtime  
- [ ] Store premi

---

Buon divertimento con **SkillWin Arcade**!
