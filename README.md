# SkillWin - Boilerplate

**App raffle skill-based: mini-giochi per vincere premi**

Stack:
- **Frontend:** Flutter + Riverpod + REST API (Dio) + Supabase Realtime
- **Backend:** FastAPI (Python)

---

## 🚀 Requisiti

### Globali
✅ Flutter 3.32+ → [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)  
✅ Android Studio (solo per avere Android SDK)  
✅ VS Code consigliato come editor  

---

## 🖥️ Struttura progetto

```
backend/    → API FastAPI
frontend/   → App Flutter (Splash → Login → Pools)
```

---

# ✅ Come avviare il BACKEND

### 1️⃣ Entra nella cartella `backend`

```bash
cd backend
```

### 2️⃣ Installa dipendenze

Se usi **Poetry**:
```bash
poetry install
```

Se usi **pip**:
```bash
pip install -r requirements.txt
```

### 3️⃣ Avvia il server FastAPI

```bash
poetry run uvicorn app.main:app --reload --port 8000
```

Oppure:
```bash
uvicorn app.main:app --reload --port 8000
```

### 4️⃣ Verifica che l'API sia online

Apri in browser:
```
http://127.0.0.1:8000/docs
```

---

# ✅ Come avviare il FRONTEND

### 1️⃣ Entra nella cartella `frontend`

```bash
cd frontend
```

### 2️⃣ Installa dipendenze

```bash
flutter pub get
```

### 3️⃣ (IMPORTANTE) Se il progetto non ha ancora le piattaforme, aggiungile:

```bash
flutter create --platforms=android,ios,web .
```

### 4️⃣ Configura il backend URL

Modifica il file:

```
lib/services/dio_client.dart
```

Imposta il tuo URL locale:

```dart
baseUrl: 'http://127.0.0.1:8000/api',
```

---

### 5️⃣ Avvia l’emulatore Android

```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

Oppure collega un telefono Android.

---

### 6️⃣ Avvia l’app su Android

```bash
flutter run -d emulator-5554
```

Oppure:
```bash
flutter run
```

---

### 7️⃣ Oppure avvia l’app su Web

1️⃣ Abilita supporto Web (una volta sola):

```bash
flutter config --enable-web
```

2️⃣ Avvia su Chrome:

```bash
flutter run -d chrome
```

---

# ✅ Primo avvio → flow app

```
Splash Screen → Login Screen → Pools Screen (chiamata REST + Supabase Realtime)
```

---

# 📚 Note aggiuntive

- Per ricevere eventi realtime → configura `supabase_realtime.dart`
- Per aggiungere mini-giochi → struttura `features/games/` plugin-friendly

---

# 🎁 TO DO Futuri

✅ Login reale con Supabase Auth  
✅ Miglior UI Pools  
✅ Aggiunta ticketing → acquisto ticket  
✅ Logica di partecipazione + vincita  
✅ Mini-giochi integrabili come moduli

---

# 🔗 Contatti

Per domande tecniche → **Gianmarco Mottola** 🚀  
Telegram / GitHub / Email