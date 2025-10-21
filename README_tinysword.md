# TinySwords Game Integration Roadmap

Questo documento definisce gli step operativi per introdurre un nuovo gioco **TinySwords** nel progetto Flutter/Flame di Tickup. L’obiettivo è realizzare un’esperienza top-down/RTS che conviva con l’attuale platform Pixel Adventure riusando quando possibile pattern e utilità già presenti nel codice.

---

## 1. Preparazione Asset & Configurazione Flutter

1. **Organizza gli asset**  
   - Mantieni la struttura attuale in `frontend/assets/TinySwords/` (`Buildings/`, `Decorations/`, `Terrain/`, `Units/`).  
   - Separa sprite animati (es. `Units/Swordsman/Walk.png`) da tile statici (`Terrain/...`).

2. **Aggiorna `pubspec.yaml`**  
   - Registra le cartelle TinySwords nella sezione `flutter.assets`.  
   - Esempio:
     ```yaml
     - assets/TinySwords/Terrain/
     - assets/TinySwords/Units/
     - assets/TinySwords/Buildings/
     - assets/TinySwords/Decorations/
     ```

3. **Preload nell’avvio**  
   - In `TinySwordsGame.onLoad` assicurati di caricare gli asset rilevanti (`await images.loadAll([...])`) o usa `images.loadFromFolder`.

---

## 2. Architettura Flame

1. **Game root**  
   - Crea `TinySwordsGame extends FlameGame` con mixin `HasCollisionDetection`, `TapCallbacks`, `HasHoverables` (se vuoi hover su desktop).  
   - Mantieni `ValueNotifier` per HUD: risorse, selezione unità, messaggi.

2. **World & Camera**  
   - Implementa `TinySwordsWorld extends World` che carica la mappa.  
   - Usa `CameraComponent` con risoluzioni simili a Pixel Adventure ma abilita pan/zoom (scroll con drag due dita/mouse wheel).

3. **Input Controller**  
   - Registra gesture personalizzate (drag, selection box) usando `PanDetector` o componenti overlay Flutter.

---

## 3. Mappa & Pathfinding

1. **Formato mappa**  
   - Se possiedi mappe `.tmx`, importa con `TiledComponent`. Specifica layer: `Terrain`, `Obstacles`, `SpawnUnits`, `SpawnStructures`.  
   - Alternativa: crea una griglia procedurale caricando tile da `Terrain`.

2. **Collisioni statiche**  
   - Mappa tiles bloccanti in `ObstacleComponent` (estende `PositionComponent` con `RectangleHitbox`).  
   - Salva una griglia logica (`GridNode[][]`) per pathfinding.

3. **Pathfinder**  
   - Implementa servizio A* dedicato (`Pathfinder.findPath(start, goal)`).  
   - Restituisci lista di `Vector2` (centro tile) da seguire; memorizza il path nell’unità.

---

## 4. Componenti Principali

1. **UnitComponent**  
   - Estende `SpriteAnimationGroupComponent<UnitState>`.  
   - Stati minimi: `idle`, `walk`, `attack`, `die`.  
   - Carica animazioni con l’utility `loadSequencedAnimation`.  
   - Implementa:
     - `setDestination(Vector2 worldTarget)` → calcola path.  
     - `update(dt)` → muove lungo il path; ruota sprite o cambia animazione in base alla direzione.

2. **StructureComponent**  
   - Semplice `SpriteComponent` con hitbox cliccabile.  
   - Può avere un timer per produrre unità (es. `BarracksComponent.produceUnit()`).

3. **SelectableMixin**  
   - Interfaccia con `bool isSelected`, `void onSelected(bool)`, highlight grafico (`SelectionRingComponent`).  
   - Applicala a unità e strutture.

4. **ProjectileComponent / Combat**  
   - Se alcune unità attaccano a distanza, crea un componente con `velocity`, `damage`, `RangeHitbox`.

---

## 5. Sistema di Selezione & Controlli

1. **Click singolo**  
   - `TinySwordsGame.onTapDown` identifica componenti sotto il puntatore (`componentsAtPoint`).  
   - Aggiorna stato di selezione e HUD (es. mostra stats dell’unità).

2. **Selezione multipla**  
   - Implementa `SelectionBoxComponent` ancorato allo schermo.  
   - Durante drag, visualizza il rettangolo; al rilascio seleziona tutte le unità dentro l’area.

3. **Movimento & Azioni**  
   - Tasto destro o doppio tap imposta destinazione per unità selezionate.  
   - Se il target è una struttura o unità nemica → avvia comportamento `attack`.

---

## 6. HUD & Stato di Gioco

1. **Overlay Flutter**  
   - Crea `TinySwordsHud` con: risorse (oro, legno), pulsanti d’azione (Move, Attack, Build), minimappa opzionale.

2. **Gestione risorse**  
   - Implementa `ResourceManager` centralizzato con metodi `addResource`, `consume`.  
   - Le strutture possono generare risorse nel tempo.

3. **Pannello produzione**  
   - Per le strutture selezionate mostra un elenco di unità producibili; al click invoca `TinySwordsGame.spawnUnit(...)`.

---

## 7. Integrazione con l’app

1. **Routing**  
   - Crea nuova pagina Flutter: `TinySwordsMenuPage` (struttura simile a `PixelAdventureMenuPage`).  
   - Fornisci entry point nel menu giochi o profilo.

2. **Game Screen**  
   - `TinySwordsGameScreen` con `GameWidget(game: TinySwordsGame(), overlayBuilderMap: {...})`.  
   - Gestisci orientamento (top-down spesso in portrait, verifica preferenza).

3. **Persistenza avatar**  
   - Se prevedi avatar o skin dedicati al gioco, espandi `avatar_catalog` e metadata come fatto per Pixel Adventure.

---

## 8. QA & Tooling

1. **Testing rapido**  
   - Aggiungi comando `make run_tinyswords` o analoghi script `flutter run -t lib/main_tinyswords.dart`.

2. **Debug utilities**  
   - Componenti per mostrare griglia, path attivo, FPS, stats unità (`TextComponent` overlay).

3. **Documentazione**  
   - Aggiorna README principale con sezione TinySwords.  
   - Mantieni changelog e screenshot per stakeholder.

---

## 9. Iterazioni Future

- **IA nemica**: script per spawnare ondate, difendere basi, gestire stati (patrol, chase).  
- **Multiplayer/Online**: definire sincronia, server o turni asincroni.  
- **Bilanciamento**: valori velocità, danni, costi risorse.  
- **Modularità**: estrarre componenti comuni (es. `TopDownUnit`, `TopDownStructure`) in un package condiviso se aggiungerai altri giochi simili.

---

## Risorse Utili

- [Flame Docs – Isometric Tilemaps](https://docs.flame-engine.org/main/isometric_tile_map.html)  
- [Flame Pathfinding tutorial (A*)](https://docs.flame-engine.org/main/recipes/path_finding.html)  
- [Flame GameWidget overlays](https://docs.flame-engine.org/main/widget_game.html)  
- [Flutter GestureDetector per interfacce custom](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)

Segui questi passi in ordine incrementale per ottenere rapidamente un prototipo TinySwords giocabile e successivamente raffinarlo con feature avanzate.
