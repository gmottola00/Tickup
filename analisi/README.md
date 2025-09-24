# SkillWin - NEXT STEP

Ottimo lavoro! Hai già completato le **basi critiche** del progetto SkillWin:
✅ backend con DB e primi endpoint
✅ frontend con auth e primi giochi

Ora è il momento perfetto per fare il **salto di qualità**, passando da un prototipo a un'app pronta per utenti reali.

---

# 🔭 Obiettivo fase 2: MVP funzionante, testabile, e pronto per feedback

Ecco i **prossimi passi strategici**, ordinati per priorità e valore:

---

## 🧩 1. **Integrazione completa tra Auth, Ticketing e Pool**

* [ ] Associa utente loggato ai ticket acquistati
* [ ] Salva transazioni e partecipazioni (anche se i giochi sono solo di test)
* [ ] Ogni utente vede i **propri ticket attivi e vinti**
* [ ] Ogni `raffle_pool` ha stato: `open` / `closed` / `in_game` / `finished`

---

## 🎮 2. **Logica base dei giochi con premio finale**

* [ ] Ogni gioco assegna un punteggio all’utente
* [ ] Quando finisce un pool → assegna premio al top scorer
* [ ] Salva nel backend:

  * punteggio
  * tempo impiegato
  * ID utente
  * ID gioco

---

## 💳 3. **Simulazione pagamento/acquisto ticket**

* [ ] Flusso: utente clicca "Acquista ticket" → decrementa stock pool → assegna ticket
* [ ] (Facoltativo) Simula pagamento con saldo fittizio per testing (es. wallet 1000 coins)

---

## 🛰️ 4. **Realtime updates su frontend**

* [ ] Aggiorna in tempo reale:

  * numero di partecipanti
  * numero di ticket ancora disponibili
  * vincitore assegnato (se chiuso)

---

## 📦 5. **Pulizia dati e struttura stabile**

* [ ] Rifinisci il modello dati nel backend (`ticket`, `game_session`, `score`, `winner`)
* [ ] Aggiungi validazioni e gestione errori (es. non acquistare ticket se pool chiuso)
* [ ] Aggiungi test API (es. con Pytest)

---

## 🧪 6. **User test interni e debug**

* [ ] Fai login con 2 utenti diversi e gioca
* [ ] Prova a chiudere un pool e determinare vincitore
* [ ] Testa UX su mobile/emulatore

---

## 💡 7. **Estetica e polish**

* [ ] Migliora design PoolsScreen
* [ ] Aggiungi immagini, transizioni e animazioni
* [ ] Mostra cronologia ticket, partite giocate, classifiche

---

## 🎯 8. **Prepara il lancio privato (beta)**

* [ ] Se vuoi testare con amici →

  * deploya su Vercel/Render (backend) + Firebase Hosting (frontend web)
  * oppure builda l’APK e caricalo su telefono

---

# 📦 Bonus (se vuoi andare oltre)

* [ ] Multigiocatore asincrono: punteggio + classifica
* [ ] Limite tempo di gioco / tentativi
* [ ] Gestione di premi multipli e sponsor
* [ ] Admin Panel: crea pools, gestisci stock, consulta dati

---

## ✅ Prossimo step consigliato da fare ORA

* Annulla ticket dopo un massimo di tempo
