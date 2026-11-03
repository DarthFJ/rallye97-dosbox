# Rallye Racing 97 für Windows

Startet *Rallye Racing 97* (Network Q RAC Rally Championship, 1996) auf aktuellen Windows-PCs, ohne Einrichtung. DOSBox Staging wird automatisch in diesen Ordner geladen und nicht im System installiert.

Das Repo enthält **keine Spieldaten**. Du brauchst deine eigene CD oder ein vollständiges Abbild davon.

## So geht's

1. Lade diesen Ordner herunter.
2. Kopiere dein Abbild hinein (`.cue` und `.bin`) oder lege die CD ein.
3. Starte `Starten.bat`.

Beim ersten Start werden das Spiel installiert und DOSBox geladen, das dauert meist unter einer Minute. Einbinden musst du das Abbild nicht, das erledigt DOSBox selbst.

| Datei | Zweck |
|---|---|
| `Starten.bat` | Startet das Spiel und installiert es vorher, falls nötig |
| `Installieren.bat` | Installiert nur, ohne das Spiel zu starten |
| `Deinstallieren.bat` | Entfernt Spiel, Spielstände und DOSBox, Abbild und Skripte bleiben |

Eine Internetverbindung ist nur beim ersten Start nötig.

## Abbild oder CD

- **BIN/CUE (empfohlen, getestet):** enthält auch die CD-Musik.
- **ISO (noch nicht getestet):** läuft ohne CD-Musik.
- **CD (noch nicht getestet):** Sie muss beim Spielen im Laufwerk liegen.

Das Medium muss im Hauptverzeichnis die Datei `68060` enthalten, sonst beendet sich das Spiel kommentarlos. Bei unvollständigen Abbildern bricht die Installation deshalb mit einem Hinweis ab.

## Bewährte Einstellungen

Sie stehen in `rallye.conf`:

| Einstellung | Wert | Grund |
|---|---|---|
| `cpu_cycles_protected` | `100000` | Bei 150.000 kratzen die Soundeffekte, stark gesenkt ruckelt das Spiel |
| `core` | `dynamic` | Schnellere CPU-Emulation |
| `sbtype` | `sb16` | Bester Ton |
| `timed` | `off` | Verhindert ungewollte Bewegungen im Menü mit dem Gamepad |

Der beste Zyklenwert kann auf anderen PCs abweichen. Im Spiel änderst du ihn mit `Strg+F11` und `Strg+F12`.

## Gamepad

Getestet mit dem 8BitDo Ultimate 2. DOSBox gibt es als Joystick an das Spiel weiter.

Stelle im Spiel unter Spieloptionen → Kontrolloptionen die Steuerung auf Joystick und die Beschleunigung auf Knöpfe. Kalibriere den Joystick dort anschließend.

## Tastatur

| Aktion | Taste |
|---|---|
| Gas | `Ä` |
| Bremse | `-` |
| Links / Rechts | `Y` / `X` |
| Hochschalten / Runterschalten | `Ö` / `.` |
| Vollbild umschalten | `Alt+Enter` |
