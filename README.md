# Star Trek Sandbox – Godot-Rewrite (MVP)

Erste spielbare Grundlage, basierend auf `godot_rewrite_referenz.md`.
Engine-Version: Godot **4.3+** (GDScript).

## Projekt oeffnen

1. Godot 4.3 oder neuer starten.
2. "Import" -> Ordner `StarTrekSandbox` (mit `project.godot`) auswaehlen.
3. Play druecken (F5) -> startet `scenes/Main.tscn`.

## Was bereits funktioniert

- **World-Seed (Minecraft-Stil, Referenz Abschnitt 3):** Beim allerersten
  Start wird ein zufaelliger 64-Bit-Seed erzeugt und in
  `user://savegame/world_meta.json` gespeichert. Sektor-Inhalte werden aus
  `(world_seed, sector_id)` per SHA256 deterministisch abgeleitet
  (`SectorUtils.seed_for_sector`).
- **Sektor-Generierung:** 35 % Spawn-Chance pro Sektor, Sternposition, SOI
  300-750, 0-5 Planeten mit gewichteter Klassenwahl (D/H/K/L/M/N/Y + Gasriesen
  J/T/6/7/9), Orbit-Radius/-Winkel, Namen aus Praefix+Suffix+roemischer Ziffer.
- **Chunk-Loading:** `WorldManager` laedt/entlaedt den 3x3x3-Nachbarschaftsblock
  je nach Spielerposition, spawnt Sterne/Planeten/Stationen/NPC-Schiffe.
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
  (Stationen/Schiffe/Ressourcen-Overrides) in `user://savegame/sectors/*.json`.

## Bewusste Vereinfachungen / naechste Schritte

- **Persistenz ist JSON-basiert**, nicht SQLite (siehe Referenz Abschnitt 2,
  dort als gleichwertige Alternative genannt). Falls gewuenscht, spaeter
  gegen das `godot-sqlite`-GDExtension tauschbar — `GameDatabase.gd` kapselt
  bereits die komplette Schnittstelle dafuer.
- **Prozedurale Planetentexturen** (Referenz Abschnitt 8) fehlen noch;
  Planeten haben aktuell nur eine Flaechenfarbe je Klasse.
- **Mond-Spawning** ist als Komponente (`Moon.gd`) vorbereitet, aber noch
  nicht automatisch in die Sektorgenerierung verdrahtet.
- **Sol-System bei (0,0,0)** beim allerersten Start (Referenz Abschnitt 2,
  letzter Punkt) ist noch nicht hart codiert — aktuell entscheidet wie bei
  jedem anderen Sektor der Zufall, ob dort ein System spawnt.
- **Bau-/Abbau-Gameplay** (Stationen bauen, Planeten abbauen) ist nur als
  Datenstruktur vorbereitet (`GameDatabase.add_station/add_ship/
  update_planet_resource`), aber noch nicht mit echtem Gameplay verbunden.
- **Skybox** ist aktuell ein einfacher `ProceduralSkyMaterial`-Platzhalter,
  noch kein Sternenfeld-Panorama (Referenz Abschnitt 9).
- **Lokalisierung/Uebersetzung:** Texte sind aktuell direkt im Code
  (z. B. `HelpOverlay._help_text()`). Geplant: spaeter ein
  `Locale`-Autoload, das Texte aus `res://data/locale/<sprache>.json`
  (Key -> uebersetzter Text) laedt, sodass neue Sprachen ohne Code-Aenderung
  ergaenzt werden koennen.

## Projektstruktur

```
project.godot
scripts/
  autoload/        GameDatabase, SectorUtils, StarNames, PlanetClassDB,
                    SectorGenerator, InputSetup (alle als Singleton registriert)
  world/            WorldManager (Chunk-Loading), SOITracker
  entities/         Ship, Star, Planet, Moon, Station, NPCShip
  camera/           CameraRig (Follow/Frei)
  ui/               GalaxyMap, HelpOverlay
  main/             Main (verdrahtet alles)
scenes/             Minimal-Szenen (Root-Node + zugehoeriges Skript)
```
