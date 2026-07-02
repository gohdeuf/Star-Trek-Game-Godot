# Star Trek Sandbox – Godot-Rewrite (MVP)

Erste spielbare Grundlage, basierend auf `godot_rewrite_referenz.md`.
Engine-Version: Godot **4.3+** (GDScript).

## Projekt oeffnen

1. Godot 4.3 oder neuer starten.
2. "Import" -> Ordner `StarTrekSandbox` (mit `project.godot`) auswaehlen.
3. Play druecken (F5) -> startet `scenes/Main.tscn`.

## Wo landen meine Speicherdaten?

**Wichtig:** `user://` ist KEIN Ordner im Projektverzeichnis! Godot legt
Speicherdaten in einem versteckten, OS-spezifischen Nutzerdaten-Ordner ab
(Projektname = "Star Trek Sandbox", siehe `project.godot`):

- **Windows:** `%APPDATA%\Godot\app_userdata\Star Trek Sandbox\`
- **Linux:** `~/.local/share/godot/app_userdata/Star Trek Sandbox/`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/Star Trek Sandbox/`

Am einfachsten: im Godot-Editor **Projekt -> Nutzerdaten-Ordner oeffnen**.
Zusaetzlich gibt das Spiel den exakten Pfad beim Start im Output-Panel aus
(`GameDatabase: Speicherort = ...`), ebenso nach jedem erfolgreichen Speichern
der `world_meta.json`.

## Was bereits funktioniert

- **World-Seed (Minecraft-Stil, Referenz Abschnitt 3):** Beim allerersten
  Start fragt ein Dialog optional nach einem eigenen Seed (Text oder Zahl);
  leer lassen erzeugt einen zufaelligen 64-Bit-Seed. Wird in
  `user://savegame/world_meta.json` gespeichert. Sektor-Inhalte werden aus
  `(world_seed, sector_id)` per SHA256 deterministisch abgeleitet
  (`SectorUtils.seed_for_sector`).
  **Bugfix:** Der Seed wird jetzt als String statt als Zahl im JSON abgelegt,
  da JSON nur 64-Bit-Floats kennt und ein grosser 64-Bit-Int-Seed dabei
  vorher Praezision verlor (Ursache fuer "andere Sektorinhalte nach Neustart").
- **Sol-System bei (0,0,0):** Der Ursprungssektor enthaelt in JEDER Welt
  immer das hartcodierte Sol-System mit 9 Planeten (Merkur bis Pluto,
  inkl. Monden wie Luna, Phobos/Deimos, den vier grossen Jupitermonden usw.),
  unabhaengig vom World-Seed und der sonstigen 35%-Spawn-Chance.
- **Sektor-Generierung:** 35 % Spawn-Chance pro Sektor, Sternposition, SOI
  300-750, 0-5 Planeten mit gewichteter Klassenwahl (D/H/K/L/M/N/Y + Gasriesen
  J/T/6/7/9), Orbit-Radius/-Winkel, Namen aus Praefix+Suffix+roemischer Ziffer.
  **Bugfix:** Der Bahnabstand zwischen Planeten wird jetzt aus den
  tatsaechlichen Planetenradien berechnet (vorher zu klein/fix -> Planeten
  konnten sich insbesondere bei grossen Gasriesen fast beruehren/ueberlappen).
- **Mond-Spawning:** Planeten bekommen automatisch 0-2 (fest) bzw. 0-4
  (Gasriesen) Monde, mit Namen, Orbit-Radius und Winkelgeschwindigkeit.
- **Prozedurale Planetentexturen:** Aus `FastNoiseLite` generiert (rocky:
  Farbverlauf + optionale Polkappen; Gasriesen: Breitengrad-Baender +
  Turbulenz), auf der Einheitskugel gesampelt -> automatisch nahtlos.
  Seed kombiniert World-Seed + Planetenname, gecacht pro Planet.
- **Skybox:** Laedt automatisch ein Panorama-Asset aus
  `res://assets/skybox/starfield_panorama.png`, falls vorhanden (siehe
  `assets/skybox/LIESMICH.txt` fuer die Godot-Import-Falle). Ohne Asset wird
  ein prozedurales, World-Seed-basiertes Sternenfeld generiert.
- **Lokalisierung:** `Locale`-Autoload laedt Texte aus
  `res://data/locale/<sprache>.json` (Key -> uebersetzter Text). Neue
  Sprachen: einfach eine weitere JSON-Datei nach diesem Schema anlegen, KEINE
  Code-Aenderung noetig. Beim Start wird automatisch versucht, die OS-Sprache
  zu verwenden (`OS.get_locale_language()`); Fallback ist Deutsch (`de.json`).
  **Shift + L** schaltet zur Laufzeit zwischen allen gefundenen Sprachen durch (fuer
  schnelles Testen neuer Uebersetzungen, aendert nichts dauerhaft/persistent).
  Fehlt ein Key in der gewaehlten Sprache, wird zuerst auf Deutsch, dann auf
  den rohen Key selbst zurueckgefallen (fehlende Uebersetzungen fallen so
  sofort im Spiel auf statt leer zu bleiben). Aktuell befuellt: `de.json`
  (Basis) und `en.json` (Beispiel/Vorlage fuer weitere Sprachen).
  Planeten-/Sternnamen bleiben bewusst NICHT lokalisiert -- das sind
  prozedural generierte Weltdaten aus dem SectorGenerator, keine UI-Texte.
- **Chunk-Loading:** `WorldManager` laedt/entlaedt den 3x3x3-Nachbarschaftsblock
  je nach Spielerposition, spawnt Sterne/Planeten/Monde/Stationen/NPC-Schiffe.
- **Sphere-of-Influence-Tracking:** `SOITracker` mit Zustandsmaschine
  INTERSTELLAR/SYSTEM und Signalen `enter_system`/`exit_system`.
- **Spielerschiff:** WASD + Pfeiltasten (Pitch/Yaw) + Q/E (Roll) +
  Space/Strg (Hoch/Runter), aus Primitiven gebautes Enterprise-Modell.
- **Kamera:** Follow-Modus standardmaessig, F10 -> freie Kamera
  (RMB+Maus = Drehen, WASD/Space/Strg = Fliegen, Shift = Boost, Scroll = Speed).
- **Galaxiekarte:** Tab oeffnet/schliesst, Zoom/Pan, Hoehenanzeige (^/v/~),
  Spieler-Marker mit Rotation, Info-Text.
- **Persistenz:** Spielerposition + World-Seed in
  `user://savegame/world_meta.json`; vom Spieler veraenderte Sektordaten
  (Stationen/Schiffe/Ressourcen-Overrides) in `user://savegame/sectors/*.json`
  (diese Dateien entstehen erst, sobald Bau-/Abbau-Gameplay existiert, siehe
  unten -- aktuell ruft noch niemand `add_station`/`add_ship`/
  `update_planet_resource` auf).

## Bewusste Vereinfachungen / naechste Schritte

- **Persistenz ist JSON-basiert**, nicht SQLite (siehe Referenz Abschnitt 2,
  dort als gleichwertige Alternative genannt). Falls gewuenscht, spaeter
  gegen das `godot-sqlite`-GDExtension tauschbar — `GameDatabase.gd` kapselt
  bereits die komplette Schnittstelle dafuer.
- **Bau-/Abbau-Gameplay** (Stationen bauen, Planeten abbauen) ist nur als
  Datenstruktur vorbereitet (`GameDatabase.add_station/add_ship/
  update_planet_resource`), aber noch nicht mit echtem Gameplay verbunden.
  Deshalb entstehen aktuell auch noch keine `sectors/*.json`-Dateien.
- **Weitere Sprachen:** Infrastruktur steht (siehe oben). Um z. B.
  Franzoesisch zu ergaenzen: `data/locale/de.json` kopieren nach
  `data/locale/fr.json`, alle Werte uebersetzen (Keys unveraendert lassen),
  fertig -- kein Code-Aenderung noetig. Neue Keys fuer zukuenftige Features
  bitte in ALLEN vorhandenen `data/locale/*.json`-Dateien ergaenzen, sonst
  greift automatisch der Deutsch-Fallback.

## Projektstruktur

```
project.godot
assets/
  skybox/           Ablageort fuer eigenes Skybox-Panorama (siehe LIESMICH.txt)
data/
  locale/           de.json, en.json, ... (siehe Locale-Autoload)
scripts/
  autoload/         Locale, GameDatabase, SectorUtils, StarNames, PlanetClassDB,
                     SectorGenerator, InputSetup (alle als Singleton registriert)
  world/            WorldManager (Chunk-Loading), SOITracker
  entities/         Ship, Star, Planet, Moon, Station, NPCShip
  camera/           CameraRig (Follow/Frei)
  ui/               GalaxyMap, HelpOverlay, WorldSeedDialog
  main/             Main (verdrahtet alles)
scenes/             Minimal-Szenen (Root-Node + zugehoeriges Skript)
```
