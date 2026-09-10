param([switch]$WithShotSignal)
$ErrorActionPreference = 'Stop'
$hunchPackRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($hunchPackRoot -match '(?i)\\OneDrive\\') { throw 'Extract this launcher pack under C:\dev or another non-OneDrive path.' }
$hunchLocalMod = Join-Path $hunchPackRoot '@HUNCH'
$hunchMission = Join-Path $hunchPackRoot 'HUNCH_Test.VR\mission.sqm'
if (!(Test-Path -LiteralPath (Join-Path $hunchLocalMod 'addons\hunch.pbo'))) { throw "Missing HUNCH addon: $hunchLocalMod" }
if (!(Test-Path -LiteralPath $hunchMission)) { throw "Missing test mission: $hunchMission" }
$hunchRunning = @(Get-Process arma3*,TerrainBuilder,ObjectBuilder -ErrorAction SilentlyContinue)
if ($hunchRunning.Count -gt 0) { throw 'An Arma or map-tools session is already running. Close it before starting HUNCH; this pack will not interrupt it.' }

function Get-HunchSteamLibraries {
    $hunchLibraries = [System.Collections.Generic.List[string]]::new()
    foreach ($hunchCandidate in @('C:\Program Files (x86)\Steam','C:\Program Files\Steam','D:\SteamLibrary')) {
        if (Test-Path -LiteralPath $hunchCandidate) { [void]$hunchLibraries.Add($hunchCandidate) }
    }
    try {
        $hunchSteamPath = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath
        if ($hunchSteamPath) { [void]$hunchLibraries.Add(($hunchSteamPath -replace '/','\')) }
    } catch {}
    foreach ($hunchSteamRoot in @($hunchLibraries | Select-Object -Unique)) {
        $hunchVdf = Join-Path $hunchSteamRoot 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $hunchVdf) {
            foreach ($hunchMatch in [regex]::Matches((Get-Content -Raw -LiteralPath $hunchVdf),'"path"\s+"([^"]+)"')) {
                [void]$hunchLibraries.Add(($hunchMatch.Groups[1].Value -replace '\\\\','\'))
            }
        }
    }
    @($hunchLibraries | Select-Object -Unique)
}

$hunchArma = $null; $hunchCba = $null; $hunchShotSignal = $null
foreach ($hunchLibrary in Get-HunchSteamLibraries) {
    $hunchCandidate = Join-Path $hunchLibrary 'steamapps\common\Arma 3\arma3_x64.exe'
    if (!$hunchArma -and (Test-Path -LiteralPath $hunchCandidate)) { $hunchArma = $hunchCandidate }
    $hunchCandidate = Join-Path $hunchLibrary 'steamapps\workshop\content\107410\450814997'
    if (!$hunchCba -and (Test-Path -LiteralPath (Join-Path $hunchCandidate 'addons\cba_main.pbo'))) { $hunchCba = $hunchCandidate }
    $hunchCandidate = Join-Path $hunchLibrary 'steamapps\workshop\content\107410\3426116212'
    if (!$hunchShotSignal -and (Test-Path -LiteralPath (Join-Path $hunchCandidate 'addons\ShotSignal.pbo'))) { $hunchShotSignal = $hunchCandidate }
}
if (!$hunchArma) { throw 'Arma 3 was not found in the registered Steam libraries.' }
if (!$hunchCba) { throw 'CBA_A3 was not found. Subscribe/install Workshop item 450814997, then run this pack again.' }
if ($WithShotSignal -and !$hunchShotSignal) { throw 'Shot Signal was requested but Workshop item 3426116212 is not installed.' }
$hunchProfile = Join-Path $hunchPackRoot 'Profiles'
New-Item -ItemType Directory -Path $hunchProfile -Force | Out-Null
$hunchMods = @($hunchCba,$hunchLocalMod)
if ($WithShotSignal) { $hunchMods += $hunchShotSignal }
$hunchModArgument = '-mod="' + ($hunchMods -join ';') + '"'
$hunchProfileArgument = '-profiles="' + $hunchProfile + '"'
# Passing a mission.sqm opens the source mission in Arma's editor with the selected mods loaded.
# Press Preview to enter the isolated HUNCH test range; no existing mission/profile is modified.
$hunchArgs = @('-noSplash','-skipIntro','-world=VR',$hunchProfileArgument,'-name=HUNCH_Launcher',$hunchModArgument,'"' + $hunchMission + '"')
Start-Process -FilePath $hunchArma -ArgumentList $hunchArgs -WorkingDirectory (Split-Path $hunchArma)
