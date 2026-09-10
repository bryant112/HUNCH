param([switch]$WithoutHunch, [switch]$WithShotSignal)
$ErrorActionPreference = 'Stop'
$hunchRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($hunchRoot -match '(?i)\\OneDrive\\') { throw 'OneDrive project writes forbidden' }
$hunchArma = 'C:\Program Files (x86)\Steam\steamapps\common\Arma 3\arma3_x64.exe'
$hunchWorkshop = 'C:\Program Files (x86)\Steam\steamapps\workshop\content\107410'
$hunchRunning = @(Get-Process arma3*,TerrainBuilder,ObjectBuilder -ErrorAction SilentlyContinue)
if ($hunchRunning.Count -gt 0) { throw 'An Arma or map-tools session is running. Close it yourself when ready; this launcher will not interrupt it.' }
$hunchProfile = Join-Path $hunchRoot 'runtime\profiles'
New-Item -ItemType Directory -Path $hunchProfile -Force | Out-Null
$hunchMods = @((Join-Path $hunchWorkshop '450814997'))
if (!$WithoutHunch) { $hunchMods += Join-Path $hunchRoot 'build\@HUNCH' }
if ($WithShotSignal) { $hunchMods += Join-Path $hunchWorkshop '3426116212' }
foreach ($hunchMod in $hunchMods) { if (!(Test-Path -LiteralPath $hunchMod)) { throw "Missing mod: $hunchMod" } }
$hunchMission = Join-Path $hunchRoot 'mission\HUNCH_Test.VR\mission.sqm'
# Explicit interactive test launch. Existing Steam library and Workshop content are read only.
$hunchArgs = @('-noSplash','-skipIntro','-world=VR',('-profiles="'+$hunchProfile+'"'),'-name=HUNCH_Test',('-mod="'+($hunchMods -join ';')+'"'),('"'+$hunchMission+'"'))
Start-Process -FilePath $hunchArma -ArgumentList $hunchArgs -WorkingDirectory (Split-Path $hunchArma)
