# Categoria & Sottocategoria Initiative

## Visione generale
- Introdurre un modello di tassonomia gerarchica condiviso da premi (`Prize`) e pool (`RafflePool`) con categorie e sottocategorie riutilizzabili.
- Aggiornare backend, API, frontend e processi operativi per supportare assegnazioni multiple e filtri avanzati senza impatto sugli utenti durante la migrazione.
- Fornire strumenti di amministrazione e monitoraggio per mantenere coerente l’albero categorie nel tempo.

## Obiettivi chiave
1. Disegnare e implementare nuove tabelle dedicate alle categorie con campi espliciti per gerarchia, metadati e assegnazioni.
2. Migrare i dati esistenti dalla colonna `prize.category` alle nuove relazioni senza perdere storicità.
3. Offrire API e UI che permettano creazione, modifica e ricerca di premi/pool per categoria.
4. Garantire test automatizzati, operazioni di rollback e documentazione operativa.

---

## Modello Dati proposto

### Tabella `catalog_category`
- `category_id` (UUID, PK, default `uuid_generate_v4()`) – identificatore univoco.
- `name` (VARCHAR(120), NOT NULL) – nome visibile agli utenti.
- `slug` (VARCHAR(120), NOT NULL) – identificatore URL friendly, unico per `parent_id`.
- `parent_id` (UUID, FK → `catalog_category.category_id`, nullable) – riferimento alla categoria padre; NULL per categorie root.
- `depth` (INTEGER, NOT NULL, default 0) – livello della categoria (0=root).
- `path_code` (VARCHAR(255), NOT NULL) – stringa codificata (es. `root/child/grandchild`) per query gerarchiche veloci.
- `assignable_to` (ENUM: `PRIZE`, `POOL`, `BOTH`, NOT NULL, default `BOTH`) – ambito su cui può essere assegnata.
- `is_leaf` (BOOLEAN, NOT NULL, default TRUE) – flag calcolato per ottimizzare la UI.
- `display_order` (INTEGER, default 0) – ordinamento custom nella stessa famiglia.
- `created_at` (TIMESTAMPTZ, default `now()`) – data creazione record.
- `updated_at` (TIMESTAMPTZ, on update `now()`) – data ultima modifica.
- Vincoli:
  - `UNIQUE (parent_id, slug)` per evitare duplicati tra fratelli.
  - `CHECK (depth >= 0)` e `CHECK (path_code <> '')`.
  - Indici su `parent_id`, `slug`, `path_code` per query gerarchiche e ricerche testuali.

### Tabella `prize_category_link`
- `prize_id` (UUID, PK part, FK → `prize.prize_id`, ON DELETE CASCADE) – riferimento al premio.
- `category_id` (UUID, PK part, FK → `catalog_category.category_id`, ON DELETE CASCADE) – categoria associata.
- `is_primary` (BOOLEAN, NOT NULL, default FALSE) – indica la categoria principale del premio.
- `assigned_at` (TIMESTAMPTZ, NOT NULL, default `now()`) – data di assegnazione.
- `assigned_by` (UUID, FK → `app_user.user_id`, nullable) – utente che ha effettuato l’assegnazione (admin o owner).
- Vincoli:
  - `CHECK` per garantire che un premio abbia al massimo una categoria primaria (indice parziale su `is_primary = TRUE`).
  - Indice su `(category_id, is_primary)` per filtri.

### Tabella `pool_category_link` (opzionale, se i pool devono divergere dal premio)
- `pool_id` (UUID, PK part, FK → `raffle_pool.pool_id`, ON DELETE CASCADE).
- `category_id` (UUID, PK part, FK → `catalog_category.category_id`, ON DELETE CASCADE).
- `origin` (ENUM: `INHERITED`, `MANUAL`, NOT NULL, default `INHERITED`) – se la categoria deriva dal premio o è stata assegnata manualmente.
- `is_primary` (BOOLEAN, NOT NULL, default FALSE).
- `assigned_at` (TIMESTAMPTZ, NOT NULL, default `now()`).
- Vincoli analoghi alla tabella dei premi.

### Modifiche tabelle esistenti
- `prize`:
  - Deprecare `category` (Text) in favore delle relazioni.
  - Aggiungere `primary_category_id` (FK → `catalog_category.category_id`, nullable) come denormalizzazione opzionale per query rapide.
- `raffle_pool`:
  - Valutare `primary_category_id` (FK) per consentire filtri rapidi lato pool senza join.
- `app_user` o tabelle correlare:
  - Nessun cambio obbligatorio, ma considerare permessi admin per gestione categorie.

---

## Backend Roadmap

### 1. Progettazione dettagliata
- Finalizzare l’ER diagram includendo vincoli, indici e strategie di path (`path_code` aggiornato via trigger).
- Definire massima profondità supportata e regole di naming (slug derivato da `name`, lower-case, unique).
- Plan decisione su `pool_category_link`: se la categoria del pool coincide sempre con la primaria del premio, il campo denormalizzato è sufficiente.

### 2. Migrazioni database
- **Migrazione A**:
  - Creare enum `category_assignable_to`.
  - Creare `catalog_category` con tutti i campi e vincoli sopra elencati.
  - Creare `prize_category_link` (e `pool_category_link` se necessario).
  - Aggiungere `primary_category_id` alle tabelle esistenti (nullable + FK deferrable).
  - Trigger/constraint per aggiornare `is_leaf` su update/insert/delete.
- **Migrazione B**:
  - Popolare tassonomia iniziale (root + categorie note) tramite `INSERT` o script alembic.
  - Backfill `prize_category_link` per ogni `Prize.category` esistente creando categorie placeholder se mancanti.
  - Aggiornare `primary_category_id` dei premi/pool coerentemente.
- **Migrazione C**:
  - Rimuovere colonna `prize.category` dopo che l’applicazione è passata alla nuova logica.
  - Aggiornare eventuali viste/materializzate o report legacy.
- **Rollback plan**:
  - Script per spostare categorie dalla tabella ponte di nuovo su colonna `category`.
  - Preservare dump pre-migrazione e definire checkpoint di deploy.

### 3. Modelli ORM & Layer applicativo
- Definire classi SQLAlchemy per `CatalogCategory`, `PrizeCategoryLink`, `PoolCategoryLink`.
- Aggiornare `Prize` con relazioni `categories` (many-to-many) e proprietà helper `primary_category`.
- Aggiornare `RafflePool` con relazione/denormalizzazione.
- Aggiornare repository:
  - Richiede metodi per assegnare categorie, validare `assignable_to`, e gestire transazioni per aggiornare link + campi denormalizzati.
  - Esporre filtri per ottenere premi/pool per `category_id`, `slug`, `path_code`.
- Implementare servizi di gestione categorie:
  - CRUD amministrativi.
  - Validazioni business rules (max profondità, slug unici per parent, no cicli).

### 4. API & DTO
- Aggiornare payload di creazione/aggiornamento premio:
  - Accettare `primary_category_id` e lista `additional_category_ids`.
  - Restituire in risposta: `categories` (lista di oggetti con id, nome, slug, depth, path).
- Endpoint categorie:
  - `GET /categories/tree` – restituisce albero completo o filtrato per `assignable_to`.
  - `POST /categories` – creazione categoria (solo admin).
  - `PATCH /categories/{id}` – rename, cambio parent, toggle assignable.
  - `DELETE /categories/{id}` – con check figli presenti.
- Endpoint pool (se richiesto):
  - Gestione override categorie e filtri.
- Aggiornare versioning e documentazione OpenAPI; se necessario introdurre `v2` per payload prize/pool.

### 5. Strumenti operativi & seed
- Script CLI/management command per importare tassonomia da CSV/JSON e sincronizzare path/slug.
- Job periodico (facoltativo) per validare integrità (`depth`, `is_leaf`, `path_code`).
- Documentare procedure per aggiungere nuove categorie in produzione.

### 6. Sicurezza, permessi e auditing
- Limitare gestione categorie a ruoli `ADMIN`/`CONTENT_MANAGER`.
- Tracciare `assigned_by` sui link e audit trail per modifiche categorie (event log).
- Validare input per prevenire slug malevoli o stringhe troppo lunghe.

### 7. Testing & qualità
- Unit test:
  - Trigger `is_leaf`/`path_code`.
  - Validazioni `is_primary`.
- Integration test:
  - Migrazioni (Alembic) + backfill su dataset realistico.
  - CRUD categorie + creazione premio/pool con multi-categorie.
- Performance test:
  - Query per filtri categoria e generazione albero.
  - Benchmark per ricostruire path e aggiornare profondità.
- Regression:
  - Verificare che funzioni legacy (es. acquisto ticket) restino invariate.

### 8. Deploy & monitoraggio
- Deploy in due fasi:
  1. Migrazione A + codice backward-compatible (colonna `category` ancora usata).
  2. Migrazione B + switch logica applicativa (flag feature).
  3. Migrazione C dopo stabilizzazione.
- Monitorare:
  - Errori di assegnazione (HTTP 4xx/5xx).
  - Time di risposta `GET /categories/tree`.
  - Integrità dati (nessun `prize` senza categoria primaria dopo cut-over).
- Aggiornare dashboard e alert per nuove metriche.

---

## Frontend Roadmap (Flutter)

### 1. Analisi funzionale & UX
- Confermare con Product i flussi d’uso: creazione premio, modifica, navigazione catalogo, filtri pool.
- Disegnare UX per selettore gerarchico: breadcrumb, ricerca testo, indicatori sottocategorie.
- Definire fallback mobile-first (es. bottom sheet multi-step) e desktop responsive.

### 2. Data layer & stato
- Aggiornare client API con nuovi endpoint:
  - Mapper `CatalogCategoryDto` con campi `categoryId`, `name`, `slug`, `parentId`, `depth`, `pathCode`, `assignableTo`, `isLeaf`, `displayOrder`.
  - Mapper `PrizeCategoryLinkDto` con `categoryId`, `isPrimary`, `assignedAt`.
- Introdurre store (Bloc/Provider/Riverpod) per cache categorie e invalidazioni (TTL, manual refresh).
- Gestire inizializzazione: caricare `GET /categories/tree` all’avvio e memorizzare snapshot.
- Aggiornare repository locale per inviare `primaryCategoryId` + `additionalCategoryIds` nei payload di creazione/modifica premio/pool.

### 3. UI Components
- **CategorySelector**:
  - Visualizzare albero (lista nidificata) + ricerca slug/nome.
  - Supportare selezione primaria + tag secondarie (pill chips).
  - Validare `is_leaf` per obbligare scelta su nodi finali se richiesto.
- **CategoryBadgeList**:
  - Mostrare categorie di un premio/pool (primaria evidenziata).
- **Filters**:
  - Aggiungere filtro per categorie su liste premi/pool (es. menu multi-select o tree filter).
- Aggiornare schermate:
  - `register_screen.dart`: incorporare selettore, gestire errori backend.
  - `my_prizes_page.dart`: mostrare badge e permettere edit categorie.
  - Schermate pool: integrare filtri e indicatori categorie.

### 4. UX e content
- Localizzazione/intl dei nomi categorie (gestire slug vs label).
- Gestire stati vuoti (nessuna categoria assegnata) durante fase di rollout.
- Considerare analytics: tracciare selezioni categorie per insight product.

### 5. Testing frontend
- Widget test per `CategorySelector` (selezione primaria + multiple).
- Integration test per flusso creazione premio con CSV fake e verifica payload.
- Golden test opzionale per layout componenti.
- Contract test/API mock per assicurare compatibilità con nuovi DTO.

### 6. Rilascio e comunicazione
- Feature flag client per attivare nuovo selettore dopo confirm backend.
- Aggiornare changelog app e comunicare ai team interni la nuova funzionalità.
- Preparare tutorial/FAQ per utenti finali (se app B2C).

---

## Pianificazione operativa e checklist
1. **Allineamento stakeholder**: approvare tassonomia iniziale, definire owner per manutenzione categorie.
2. **Preparazione tecnica**:
   - Implementare Migrazione A in ambiente dev + test automatici.
   - Completare modelli/servizi backend compatibili con legacy.
3. **Sviluppo frontend**: implementare componenti con API mock finché il backend non è pronto.
4. **Migrazione dati**:
   - Eseguire Migrazione B su staging, validare count categorie/premi.
   - Eseguire test E2E (creazione premio, filtro pool).
5. **Cut-over**:
   - Abilitare feature flag su backend + frontend.
   - Monitorare metriche 24h, gestire bugfix rapidi.
6. **Cleanup**:
   - Eseguire Migrazione C e rimuovere codice legacy.
   - Aggiornare documentazione tecnica e operativa.
7. **Monitoraggio continuo**:
   - Programmare review periodica tassonomia con marketing/ops.
   - Mantenere script di audit per `is_leaf`, `depth`, `path_code`.

---

## Riferimenti utili
- RFC interna sui criteri di naming categorie (se esiste).
- Linee guida SQLAlchemy/Alembic per migrazioni con `Enum`.
- Librerie Flutter consigliate per tree view (es. `flutter_treeview`) da valutare con Product.
