$ErrorActionPreference = 'Stop'
$hunchRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($hunchRoot -match '(?i)\\OneDrive\\') { throw 'OneDrive project writes forbidden' }
$hunchTools = Join-Path $hunchRoot 'build\tools'
New-Item -ItemType Directory -Path $hunchTools -Force | Out-Null
$hunchArchive = Join-Path $hunchTools 'sqfvm.zip'
$hunchUrl = 'https://github.com/SQFvm/runtime/releases/download/v2026.04.03-ed9f5f5/sqfvm_windows_x64.zip'
$hunchExpected = '8A9FFE4D553DE70949308002E02CBF71F4D2A0F3C809C11BD761E56A030B0F97'
if (!(Test-Path -LiteralPath $hunchArchive)) { Invoke-WebRequest -Uri $hunchUrl -OutFile $hunchArchive }
if ((Get-FileHash -LiteralPath $hunchArchive -Algorithm SHA256).Hash -ne $hunchExpected) { throw 'Pinned SQF-VM archive hash mismatch' }
$hunchExe = Join-Path $hunchTools 'sqfvm\sqfvm_windows_x64\sqfvm.exe'
if (!(Test-Path -LiteralPath $hunchExe)) { Expand-Archive -LiteralPath $hunchArchive -DestinationPath (Join-Path $hunchTools 'sqfvm') }
if ((Get-FileHash -LiteralPath $hunchExe -Algorithm SHA256).Hash -ne 'DF77A3D3A5C43EEB1A54F5D4CD36EB0FB05C7B0CC7B7B317F5E7D523D420E0BB') { throw 'SQF-VM executable hash mismatch' }
Write-Output "Verified pinned SQF-VM: $hunchExe"
