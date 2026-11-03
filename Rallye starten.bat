@echo off
cd /d "%~dp0"
start "" /high "%LOCALAPPDATA%\Programs\DOSBox Staging\dosbox.exe" -conf rallye.conf -noprimaryconf -nolocalconf
