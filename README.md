**Also i do not recommend playing this beta of V 0.2.0 because it might cause photosensitive epilepsy i will remove this warning once it is not there anymore**


# Star Trek Sandbox – Godot-Rewrite (v0.2.0)

Engine-Version: Godot **4.3+** (GDScript).

## Projekt oeffnen

1. Godot 4.3 oder neuer starten.
2. "Import" -> Ordner `StarTrekSandbox` (mit `project.godot`) auswaehlen.
3. Play druecken (F5) -> startet `scenes/Main.tscn`.

## Neue Features (v0.2.0)

### Waffensystem (F / T / X)
- **F (halten):** Partikel-Strahl-Emitter (PSE) – kontinuierlicher Energiestrahl, trifft NPCs in 250 Einheiten
- **T:** Torpedo abfeuern (Kaskaden- oder Antimaterie-Torpedo, je nach aktiver Waffe)
- **X:** Waffe wechseln: PSE → Kaskaden-Torpedo → Antimaterie-Torpedo
- Antimaterie-Torpedos kosten 50 Antimaterie-Einheiten (Startbestand: 50)
- NPC-Schiffe haben 200 HP und explodieren bei 0

### Alcubierre-Metrik-Antrieb (J)
- **J:** Warpantrieb ein-/ausschalten
- Aktivierung kostet 100 Deuterium, laufender Verbrauch 20/Sek
- 100× Schiffsgeschwindigkeit (15.000 Einheiten/Sek), kein Manövrieren möglich
- Visueller Effekt: animierter Torus-Ringtunnel
- Bei leerem Deuterium automatische Notabschaltung

### Stations-Docking (K)
- **K** in Stationsnähe (< 20 Einheiten): Tween richtet Schiff butterweich aus
- Andockzustand persistent in `world_meta.json`
- Erneut **K** drücken zum Ablegen

### Crew-System & Notfall-KI (N)
- **N:** Notfall-KI manuell ein-/ausschalten (zum Testen)
- Bei aktiver KI: Schiff flieht automatisch vom nächsten NPC-Schiff
- Bridge-Zustand (Normal/Beschädigt/Zerstört) beeinflusst Schiffsgeschwindigkeit
- Wird beim echten Kampfschaden automatisch ausgelöst

### Boost (Shift)
- Shift beim Fliegen: 3× Schiffsgeschwindigkeit (funktioniert nun auch beim Spielerschiff)

## Steuerung (vollständig)

| Taste | Funktion |
|-------|----------|
| W/A/S/D | Bewegen |
| Pfeiltasten | Pitch/Yaw |
| Q/E | Roll |
| Leertaste/Strg | Hoch/Runter |
| Shift | Boost (3×) |
| F (halten) | PSE-Strahl |
| T | Torpedo |
| X | Waffe wechseln |
| J | Alcubierre-Antrieb |
| K | Andocken/Ablegen |
| N | Notfall-KI |
| B | Station bauen |
| M (halten) | Ressourcen abbauen |
| Tab | Galaxiekarte |
| F10 | Freie Kamera |
| Shift+L | Sprache wechseln |
| Esc | Beenden (speichert) |

## Projektstruktur

```
project.godot
data/locale/          de.json, en.json
scripts/
  autoload/           Locale, GameDatabase, SectorUtils, StarNames,
                      PlanetClassDB, SectorGenerator, InputSetup
  camera/             CameraRig
  entities/           Ship, Star, Planet, Moon, Station, NPCShip, Torpedo
  main/               Main, PlayerActions
  systems/            WeaponSystem, WarpDrive, DockingSystem, CrewSystem  [NEU]
  ui/                 GalaxyMap, HelpOverlay, InventoryHUD, SOINotification,
                      TouchControls, TouchJoystick, WorldSeedDialog
  world/              WorldManager, SOITracker
  station/            station_connecter_1
scenes/               Minimal-Szenen (.tscn Stubs)
```
