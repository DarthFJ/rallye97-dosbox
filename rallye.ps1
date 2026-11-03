# Installiert, startet und entfernt Rallye Racing 97. Wird von den .bat-Dateien aufgerufen.
param([Parameter(Mandatory)][ValidateSet('install', 'start', 'uninstall')][string]$Action)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Root = $PSScriptRoot
$GameDir = Join-Path $Root 'hdd\RALLYC'
$DosboxDir = Join-Path $Root 'dosbox'
$RunConf = Join-Path $Root 'hdd\run.conf'

$DosboxUrl = 'https://github.com/dosbox-staging/dosbox-staging/releases/download/v0.83.0/dosbox-staging-windows-x64-v0.83.0.zip'
$DosboxSha256 = '725b915e325a6d410ce30a10989fd492fdad07f6611fff40ff77f160478810f4'

# Diese Dateien kopiert auch das Original-Installationsprogramm nicht.
$Excluded = '^(68060|AUTORUN\.INF|HANDBUCH\.PDF|INSTALL\.EXE|XTRA\.EXE|ACROBAT/.*|AUTORUN/.*|FILES/EDIT/.*|FILES/FMV/S2000|FILES/GFX/INSTBKDP\..*)$'

# Liest die Dateiliste eines ISO9660-Abbilds, auch aus rohen BIN-Sektoren.
function Open-Image($Path, $SectorSize) {
    $header = if ($SectorSize -eq 2352) { 16 } else { 0 }
    return @{ Stream = [IO.File]::OpenRead($Path); SectorSize = $SectorSize; Header = $header; Path = $Path }
}

function Read-ImageBytes($Image, [long]$Lba, [long]$Size) {
    $result = New-Object byte[] $Size
    $done = 0
    while ($done -lt $Size) {
        $Image.Stream.Position = ($Lba * $Image.SectorSize) + $Image.Header
        $chunk = [Math]::Min(2048, $Size - $done)
        [void]$Image.Stream.Read($result, $done, $chunk)
        $done += $chunk
        $Lba++
    }
    return , $result
}

function Get-ImageFiles($Image) {
    $pvd = Read-ImageBytes $Image 16 2048
    if ([Text.Encoding]::ASCII.GetString($pvd, 1, 5) -ne 'CD001') { throw "$($Image.Path) ist kein lesbares CD-Abbild." }
    $files = New-Object Collections.ArrayList
    $queue = New-Object Collections.Queue
    $queue.Enqueue(@('', [BitConverter]::ToUInt32($pvd, 158), [BitConverter]::ToUInt32($pvd, 166)))
    while ($queue.Count) {
        $prefix, $lba, $size = $queue.Dequeue()
        $data = Read-ImageBytes $Image $lba $size
        $i = 0
        while ($i -lt $data.Length) {
            $len = $data[$i]
            if ($len -eq 0) { $i = ([Math]::Floor($i / 2048) + 1) * 2048; continue }
            $nameLen = $data[$i + 32]
            $name = [Text.Encoding]::ASCII.GetString($data, $i + 33, $nameLen)
            if ($data[$i + 33] -gt 1 -or $nameLen -gt 1) {
                $extent = [BitConverter]::ToUInt32($data, $i + 2)
                $fileSize = [BitConverter]::ToUInt32($data, $i + 10)
                if ($data[$i + 25] -band 2) {
                    $queue.Enqueue(@("$prefix$name/", $extent, $fileSize))
                }
                else {
                    $clean = ($name -replace ';\d+$', '').TrimEnd('.').ToUpperInvariant()
                    [void]$files.Add(@{ Rel = "$prefix$clean"; Lba = $extent; Size = $fileSize })
                }
            }
            $i += $len
        }
    }
    return , $files
}

function Find-Medium {
    $cue = Get-ChildItem -LiteralPath $Root -Filter '*.cue' -File | Select-Object -First 1
    if ($cue) {
        $text = Get-Content -LiteralPath $cue.FullName -Raw
        $fileMatch = [regex]::Match($text, '(?im)^\s*FILE\s+"?(.+?)"?\s+BINARY')
        $modeMatch = [regex]::Match($text, '(?im)TRACK\s+0*1\s+MODE1/(2352|2048)')
        if (-not $fileMatch.Success -or -not $modeMatch.Success) { throw "$($cue.Name) hat ein unbekanntes Format." }
        $bin = Join-Path $Root $fileMatch.Groups[1].Value
        if (-not (Test-Path -LiteralPath $bin)) { throw "Die Datei $($fileMatch.Groups[1].Value) aus $($cue.Name) fehlt." }
        return @{ Kind = 'image'; Mount = $cue.FullName; Data = $bin; SectorSize = [int]$modeMatch.Groups[1].Value }
    }
    $iso = Get-ChildItem -LiteralPath $Root -Filter '*.iso' -File | Select-Object -First 1
    if ($iso) { return @{ Kind = 'image'; Mount = $iso.FullName; Data = $iso.FullName; SectorSize = 2048 } }
    foreach ($drive in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5') {
        if (Test-Path -LiteralPath "$($drive.DeviceID)\68060") { return @{ Kind = 'cd'; Mount = "$($drive.DeviceID)\" } }
    }
    throw 'Kein Spiel gefunden. Lege die CD ein oder kopiere das Abbild (.cue und .bin) in diesen Ordner.'
}

function Assert-CheckFile($Bytes) {
    if ([Text.Encoding]::ASCII.GetString($Bytes) -ne 'xyzzy') {
        throw 'Die Pruefdatei 68060 auf dem Medium ist fehlerhaft. Das Spiel wuerde damit nicht starten.'
    }
}

function Install-Game($Medium) {
    if (Test-Path -LiteralPath (Join-Path $GameDir 'RAL.EXE')) { Write-Host 'Spiel ist schon installiert.'; return }
    Write-Host 'Kopiere Spieldateien, das dauert einen Moment ...'
    $temp = "$GameDir.tmp"
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }

    if ($Medium.Kind -eq 'image') {
        $image = Open-Image $Medium.Data $Medium.SectorSize
        try {
            $files = Get-ImageFiles $image
            $check = $files | Where-Object { $_.Rel -eq '68060' }
            if (-not $check) { throw 'Diesem Abbild fehlt die Datei 68060. Das Spiel wuerde damit nicht starten. Du brauchst ein vollstaendiges Abbild.' }
            Assert-CheckFile (Read-ImageBytes $image $check.Lba $check.Size)
            foreach ($file in $files) {
                if ($file.Rel -match $Excluded) { continue }
                $target = Join-Path $temp ($file.Rel -replace '/', '\')
                [void][IO.Directory]::CreateDirectory((Split-Path $target))
                [IO.File]::WriteAllBytes($target, (Read-ImageBytes $image $file.Lba $file.Size))
            }
        }
        finally { $image.Stream.Dispose() }
    }
    else {
        Assert-CheckFile ([IO.File]::ReadAllBytes("$($Medium.Mount)68060"))
        foreach ($item in Get-ChildItem -LiteralPath $Medium.Mount -Recurse -File) {
            $rel = $item.FullName.Substring($Medium.Mount.Length).Replace('\', '/').ToUpperInvariant()
            if ($rel -match $Excluded) { continue }
            $target = Join-Path $temp ($rel -replace '/', '\')
            [void][IO.Directory]::CreateDirectory((Split-Path $target))
            Copy-Item -LiteralPath $item.FullName -Destination $target
            Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $false
        }
    }

    # Diese beiden Dateien legt sonst das Original-Installationsprogramm an.
    [void][IO.Directory]::CreateDirectory((Join-Path $temp 'VAR'))
    [IO.File]::WriteAllBytes((Join-Path $temp 'VAR\RALLYC.ZOG'), [byte[]](0x52, 0x33, 0x42, 0x35, 0x03, 0x64, 0x02))
    $ini = ";`r`n;Miles Sound System V3.50B of 7-Jul-96`r`n;`r`n`r`nDEVICE      Creative Labs Sound Blaster 16 or AWE32`r`nDRIVER      SB16.DIG`r`nIO_ADDR     220h`r`nIRQ         -1`r`nDMA_8_BIT   -1`r`nDMA_16_BIT  -1`r`n"
    [IO.File]::WriteAllText((Join-Path $temp 'MSS\DIG.INI'), $ini, [Text.Encoding]::ASCII)

    Move-Item -LiteralPath $temp -Destination $GameDir
    Write-Host 'Spieldateien sind installiert.'
}

function Get-DosboxExe {
    if (Test-Path -LiteralPath $DosboxDir) {
        return Get-ChildItem -LiteralPath $DosboxDir -Recurse -Filter 'dosbox.exe' | Select-Object -First 1 -ExpandProperty FullName
    }
}

function Install-Dosbox {
    if (Get-DosboxExe) { return }
    Write-Host 'Lade DOSBox Staging herunter ...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $Root 'dosbox-download.zip'
    try {
        Invoke-WebRequest -Uri $DosboxUrl -OutFile $zip -UseBasicParsing
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $DosboxSha256) { throw 'Der DOSBox-Download ist beschaedigt. Bitte erneut versuchen.' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $temp = "$DosboxDir.tmp"
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
        # Die Online-Hilfe ueberspringen: Sie wird nicht gebraucht und ihre Pfade sind fuer Windows oft zu lang.
        $archive = [IO.Compression.ZipFile]::OpenRead($zip)
        try {
            foreach ($entry in $archive.Entries) {
                if ($entry.FullName -match '/resources/docs/' -or $entry.Name -eq '') { continue }
                $target = Join-Path $temp ($entry.FullName -replace '/', '\')
                [void][IO.Directory]::CreateDirectory((Split-Path $target))
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target)
            }
        }
        finally { $archive.Dispose() }
        if (Test-Path -LiteralPath $DosboxDir) { Remove-Item -LiteralPath $DosboxDir -Recurse -Force }
        Move-Item -LiteralPath $temp -Destination $DosboxDir
    }
    finally { if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip } }
}

function Start-Game($Medium) {
    $hdd = Join-Path $Root 'hdd'
    $mount = if ($Medium.Kind -eq 'image') { "imgmount d `"$($Medium.Mount)`" -t iso" } else { "mount d $($Medium.Mount) -t cdrom" }
    $conf = "[autoexec]`r`nmount c `"$hdd`"`r`n$mount`r`nc:`r`ncd \rallyc`r`nrally`r`nexit`r`n"
    [IO.File]::WriteAllText($RunConf, $conf, [Text.Encoding]::ASCII)
    $process = Start-Process -FilePath (Get-DosboxExe) -WorkingDirectory $Root -PassThru -ArgumentList @(
        '-conf', "`"$(Join-Path $Root 'rallye.conf')`"", '-conf', "`"$RunConf`"", '-noprimaryconf', '-nolocalconf')
    $process.PriorityClass = 'High'
}

switch ($Action) {
    'install' {
        $medium = Find-Medium
        Install-Game $medium
        Install-Dosbox
        Write-Host 'Fertig. Starte das Spiel mit Starten.bat.'
    }
    'start' {
        $medium = Find-Medium
        Install-Game $medium
        Install-Dosbox
        Start-Game $medium
    }
    'uninstall' {
        Write-Host 'Das entfernt das installierte Spiel, deine Spielstaende und DOSBox aus diesem Ordner.'
        Write-Host 'Das Abbild und diese Skripte bleiben erhalten.'
        Write-Host -NoNewline 'Wirklich entfernen? (j/n) '
        if ([Console]::ReadLine() -notmatch '^[jJyY]') { Write-Host 'Abgebrochen.'; return }
        if (Get-Process dosbox -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$DosboxDir\*" }) { throw 'Das Spiel laeuft noch. Bitte erst beenden.' }
        foreach ($path in 'hdd', 'dosbox') {
            $full = Join-Path $Root $path
            if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
        }
        Write-Host 'Entfernt.'
    }
}
