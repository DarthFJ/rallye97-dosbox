# Rallye Racing 97 in DOSBox Staging

Getestete Konfiguration, um *Rallye Racing 97* (Network Q RAC Rally Championship, 1996) unter Windows 11 mit DOSBox Staging 0.83 zu spielen.

Das Repo enthält **keine Spieldaten**. Du brauchst ein eigenes vollständiges CD-Abbild.

## Voraussetzungen

- [DOSBox Staging](https://www.dosbox-staging.org/) (`winget install DOSBoxStaging.DOSBoxStaging`)
- Ein BIN/CUE-Abbild der Spiel-CD mit den Audiotracks, als `RALLYE97.BIN` und `RALLYE97.CUE`

Das Abbild muss die Datei `68060` im Hauptverzeichnis enthalten. Fehlt sie, beendet sich das Spiel beim Start kommentarlos, denn `RAL.EXE` prüft damit, ob die CD eingelegt ist.

Die Pfade sind auf `C:\Rallye97` ausgelegt. Liegt der Ordner woanders, passe `capture_dir` in `rallye.conf` an.

## Einrichtung

Lege die Abbild-Dateien in diesen Ordner und einen leeren Unterordner `hdd` an. Führe dann in diesem Ordner aus:

```bat
"%LOCALAPPDATA%\Programs\DOSBox Staging\dosbox.exe" -conf rallye-install.conf -noprimaryconf -nolocalconf
```

1. Installiere das Spiel nach `c:\rallyc`.
2. Die Soundeinrichtung am Ende des Installationsprogramms hängt sich auf. Schließe DOSBox dann.
3. Richte den Sound separat ein und wähle als digitalen Treiber „Sound Blaster 16“:

```bat
"%LOCALAPPDATA%\Programs\DOSBox Staging\dosbox.exe" -conf rallye-setsound.conf -noprimaryconf -nolocalconf
```

Danach startest du das Spiel mit `Rallye starten.bat`.

## Bewährte Einstellungen

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
