# HUNCH

An uncertain incoming-fire awareness overlay for Arma 3. Large, faint amber impressions suggest a direction; matching border glows cover directions outside your view. Opacity means confidence, brightness means noticeability. A conservative muzzle-flash approximation can produce a brief black dot.

**Status: packaged implementation candidate. Automated source/config/SQF checks pass; rendered Arma, weapon coverage, save/load, and performance acceptance remain unverified.** An existing Arma client/server session was left untouched during implementation.

## Independent of the map work

Everything lives in `C:\dev\arma-shot-awareness`, on `feature/hunch-v1`. No map assets, map build scripts, existing launcher profiles, or installed Workshop content are modified. CBA is the only required external addon. Shot Signal is optional and independent; HUNCH never changes its variables or controls.

The public repository is [bryant112/HUNCH](https://github.com/bryant112/HUNCH). Follow-up work is tracked in the [HUNCH v0.1 validation project](https://github.com/users/bryant112/projects/6) and the [v0.1 attended-validation milestone](https://github.com/bryant112/HUNCH/milestone/1): native event/lifecycle validation, HUD calibration, performance A/B, mod-stack compatibility, launcher-pack acceptance, and the release decision.

True single-player only. The addon deliberately does nothing in multiplayer, including playing alone through a dedicated-server launcher.

## Build and verify

Requirements: Python 3, installed Arma 3 Tools, and SQF-VM. No Python dependencies are needed.

```powershell
Set-Location C:\dev\arma-shot-awareness
.\tools\Setup-Tools.ps1
python tools/check.py
python tools/build.py
```

Outputs:

- `build/@HUNCH/addons/hunch.pbo` — addon.
- `build/HUNCH-0.1.0.zip` — portable candidate with addon, source test mission, and documentation.
- `build/missions/HUNCH_Test.VR.pbo` — packaged stock-terrain test mission.
- `build/manifest.json` — package SHA-256 and entry counts.
- `build/HUNCH-Launcher-Pack/` — extracted load-and-go pack with launch scripts.
- `build/validation/results.json` — automated evidence, with source hashes.

CfgConvert compiles the addon configuration. An original mathematical alpha mask is generated and converted with ImageToPAA. FileBank packages the result; every entry is read back and compared byte-for-byte with staged inputs. Build artifacts and downloaded tools are ignored by Git.

## Test when the current Arma session is finished

```powershell
.\tools\Launch-Test.ps1
# Separate baseline and coexistence launches:
.\tools\Launch-Test.ps1 -WithoutHunch
.\tools\Launch-Test.ps1 -WithShotSignal
```

For a packaged double-click flow, extract `build/HUNCH-Launcher-Pack/` or the same folder from `build/HUNCH-0.1.0.zip` under `C:\dev\HUNCH-launcher`, install CBA_A3, and run `Launch-HUNCH.cmd`. It finds the Arma executable and CBA in registered Steam libraries, loads the local HUNCH mod, and opens `HUNCH_Test.VR` in the editor; press Preview to enter the range. `Launch-HUNCH-With-Shot-Signal.cmd` adds installed Shot Signal independently.

The launcher refuses to start while Arma or map tools are running. It never stops another process. It uses `runtime/profiles`, the source test mission, installed CBA, and this checkout's build. No deployment to an existing Arma mission/mod directory is required.

Use the action menu for previews, reset, directions/distances, weapons, cover, weather, and load scenarios. Live fire can kill the observer. Test invulnerability is optional and changes damage-event behavior; keep it off for hit-event acceptance. Save/load is enabled for attended lifecycle checks.

Settings are under **Options → Addon Options → HUNCH**. The optional toggle key starts unassigned in Addon Controls. Defaults: amber `#D6AE68`, 15% opacity cap, ability 0.5, normal frequency, flash dots on, 30 m close-confirmed dismissal. The 40% hard cap applies only to HUNCH's layer.

## What is and is not verified

SQF-VM parses every production and test-mission SQF file and executes the actual production scoring/layout functions. State tests execute production queue, deduplication, emission, and reset code with an empty UI sentinel and metrics stub because the VM does not implement those engine interfaces. These tests do not emulate Arma's event delivery or rendering.

Read [the implementation specification](docs/SPEC.md), [acceptance procedure](docs/ACCEPTANCE.md), and [implementation evidence](docs/STATUS.md) before treating this as a finished gameplay release.

## Remove or disable

Disable HUNCH in its own Addon Options or omit `@HUNCH` from the launch preset. It does not write mission saves with persistent contacts, alter damage/AI relationships, or require edits to the terrain. Optional third-party HUDs continue normally.
