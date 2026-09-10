# HUNCH acceptance procedure

Automated source checks cannot prove engine events, render appearance, visibility, or frame-time overhead. Record each row below with date, Arma/mod versions, scenario, result, and evidence path. Leave untested rows pending.

## Prerequisites

1. Finish the currently running Arma/map session. HUNCH's launcher will refuse to interrupt it.
2. Run `tools/Setup-Tools.ps1`, `python tools/check.py`, and `python tools/build.py`.
3. Launch `tools/Launch-Test.ps1` for the separate VR range. Use the action menu.
4. Enable HUNCH diagnostics. Keep the dedicated profile's RPT under `runtime/profiles`.
5. For hit-event tests, leave optional test invulnerability OFF. It exists only to make lengthy visual/performance exercises easier. Do not mistake protected test damage behavior for normal gameplay.

## Functional matrix

| Test | Pass condition |
|---|---|
| Front/rear/left/right | Correct broad scene/border direction, including bottom for rear |
| Turning and zoom | Remembered bearing projects correctly without following a moving shooter |
| Scene edge | Complementary scene/border crossfade, no doubling or sharp jump |
| Opacity | 10/15/25% comparisons against sky/grass/dark/urban scenes remain readable |
| Dense overlap | Three sound cues maximum; combined HUNCH alpha remains bounded |
| Rifle burst | Sparse cues, no per-bullet UI pulse and no converging exact hidden location |
| Close-visible 20m | Approximately 0.25 s confirmation followed by 0.15 s dismissal |
| Close-hidden 20m | No false visual confirmation; cue only when incoming evidence exists |
| Visible 80m | Close-distance dismissal does not activate |
| 30/35m boundary | No rapid dismissal/reappearance oscillation |
| Flash clear | Small brief black dot only on a plausible currently visible flash |
| Flash occluded/offscreen/suppressed | No black dot |
| Night/NVG/thermal/fog/smoke | Conservative visibility gates; thermal alone does not prove flash |
| Pistol, rifle, MG, HMG | Record native near-miss and hit coverage independently |
| Launcher/cannon/artillery | Source cue requires original report/current visual evidence |
| Long-flight artillery / impact only | No revelation from expired/missing firing context |
| Friendly fire | Actual hit may qualify; friendly near-miss limitation remains documented |
| Own fire | No own-source cue; report masking increases briefly |
| Vehicle | Receiver rebinding, engine/interior masking; firing-area confirmation stays conservative |
| Dynamically spawned/deleted sources | Correct handler lifecycle and bounded registry |
| Save/load | No stale cues, duplicate listeners, or old projectile IDs matching new records |
| Player/team switch | Only current human player's receiver state applies |
| Death/unconscious/menu/map | Cue suspension and cleanup |
| Multiplayer / solo dedicated | No HUNCH runtime initialized |
| Shot Signal coexistence | Neither addon changes the other's state; any visual overlap is documented |
| Vanilla versus RHS/JSRS | Record overrides required; do not infer audibility from config alone |

The wall scenario may block all actual incoming events. Absence of a cue then is expected; do not inject a fake incoming event and call it native detection acceptance. Move/adjust the scenario to obtain legitimate near misses around cover if needed.

## Performance

Use the same mission, camera route, weather, loadout, invulnerability setting, unit count, and firing scenario for each A/B pair. Baseline must use `-WithoutHunch`, not just the setting toggle, so inactive hooks are excluded. Use the same map build throughout.

For quiet, moderate (8 rifles), and heavy (32 rifles) scenarios separately:

1. Warm up for 60 seconds.
2. Start the 120-second benchmark action; avoid menus/pause, death, or camera changes outside the planned route.
3. Repeat three alternating enabled/disabled pairs. Restart the scenario and profile consistently.
4. Save each scenario's RPTs separately; do not average different load scenarios together.
5. Run `python tools/analyze_benchmark.py <scenario-rpt-paths...>`.
6. Inspect HUNCH_METRIC lines separately for mean/p95 script contribution and budget degradation. The frame-time analyzer does not assert this script gate.

Required: <=2% mean FPS regression, <=1 ms p95 total frame-time increase, <0.25 ms mean HUNCH cost/frame, <0.5 ms p95 HUNCH cost/frame. Fail the candidate if a gate fails. Reduce optional work and repeat the affected scenario, rather than weakening the gate silently.

Also note event delivery counts, omitted-context counts, and skipped geometry. A fast addon that silently receives no incoming events is not a pass.

## Release decision

Only call this a validated gameplay release after the automated checks, functional matrix, compatibility runs, and performance gates have current evidence. If native events or flash visibility do not support a particular weapon, record that limitation explicitly. Preserve the packaged candidate and source hashes used for each run.
