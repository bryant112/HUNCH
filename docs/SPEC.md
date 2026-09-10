# HUNCH v0.1 implementation specification

## Product contract

HUNCH visualizes an imperfect perception of incoming-fire origin. It applies only to the human listener in true single-player. No progression, AI perception changes, network API, map markers, range/faction labels, damage edits, or sound playback changes.

The addon is a separate project and PBO, independent of map producers, Commander, Antistasi, and Shot Signal. The installed Shot Signal PBO is obfuscated; its exact implementation has not been reproduced or copied. Native Arma events implement the same general incoming-fire purpose.

## Presentation

Muted amber `#D6AE68`; color is adjustable. Main spots span roughly 35–55% of viewport height before the size multiplier. Uncertainty broadens them. Brightness scales with noticeability; alpha scales with confidence. A radial squared feather falls to transparent at the edge.

Default amber cap 0.15; configurable 0.05–0.40. A conservative global alpha budget guarantees amber overlap never exceeds its cap and dots plus amber never exceed 0.40. Separate unrelated mods are outside this budget. With several unrelated directions the conservative budget can make each fainter even where pixels do not overlap.

Scene direction is an immutable unit vector. Projection uses the current camera and zoom, with no target-object lookup. When an impression overlaps the viewport boundary, scene and border contributions crossfade using complementary weights. Entirely off-screen bearings use a broad border ellipse, approximately 6% inward depth. Direct rear maps bottom, rear-left/right toward the appropriate lower edges. Camera rotation changes projection but never updates the remembered bearing from the shooter.

Sound lifetime: fade in 0.15 s, hold 0.20 s, fade out 0.85 s. Maximum three sound impressions and two new sound emissions per second. Overlapping directions retain the stronger observation rather than averaging positions. A stronger fresh direction may replace the weakest active cue when full.

Flash dots: black, 3 px at 1080p scaled/clamped 2–6 px, 0.15 s, alpha at most 0.40, maximum two. They record observed direction and never track the muzzle. Dots require a recent confirmed incoming episode and a new plausible visible flash. No off-screen dots or replay of old flashes after delayed impacts. Unknown or suppressed flash profiles omit dots. Exact flash-pixel visibility is not measurable here; this remains a conservative approximation requiring attended validation.

## Incoming event contract

`Fired` records original projectile/muzzle context on local soldiers and LandVehicle/Air/Ship instances. Startup enumeration happens once; EntityCreated registers later sources. The source registry only owns its own handler IDs.

`Suppressed`, receiver entity `HitPart`, and `IncomingMissile` provide incoming evidence. Receivers are the player and occupied vehicle. Projectile IDs use a reset generation plus sequence number. Multiple part hits, near-miss/hit duplicates, and player/vehicle duplicates collapse by ID. Throw/Put, self-fire, missing context, non-ammunition damage, and events without an original shot record do not create cues.

Firing alone never produces a sound cue. No per-frame projectile tracking or global projectile enumeration. Native suppression generally excludes friendly near misses; friendly ammo hits may qualify. Native missile and splash events do not cover every weapon or scripted projectile. An impact cannot reveal a distant source unless its original report still qualifies.

Shot records expire at 20 s with a 2,048-record maximum. Incoming queue maximum 32; discard observations older than 0.5 s and flash work older than 0.12 s. Source episodes expire after two seconds without new incoming evidence and are limited to 32. Missing/expired source information fails closed, including long-flight artillery.

## Perception

Profile ranges before modifiers: pistol/SMG 400 m, rifle/LMG 1,000 m, heavy MG 1,800 m, launcher 1,500 m, cannon 3,000 m, artillery 5,000 m, unknown 600 m. These are tuning envelopes, not real acoustic measurements.

Profiles resolve explicit `[weapon,ammo]` overrides, inherited configuration family, then conservative unknown fallback. Weapon simulation/calibre identify family; artillery-capable source configuration adjusts the family. Suppressor AmmoCoef audibleFire is clamped 0.05–1; absent coefficients use 0.25. Unknown/suppressed flash effects omit dots. At most 512 resolved profiles are cached, resetting that cache when full.

`D = max(0, 1 - distance / effectiveRange)`.

`N = clamp(D × acousticTransmission × masking × attention)`.

`P = clamp(frequency × N × (0.6 + 0.4 × ability), 0, 0.85)`.

`C = clamp(N × (0.55 + 0.45 × ability) × directionalClarity, 0, 0.85)`.

Discard N below 0.12. A local seeded random stream samples episodes without changing the mission's global random state. One attempt per source per 0.75 s. Source-episode directional bias persists across repeated observations; do not average away the error.

Horizontal error envelope: `60 - 48*C` degrees; vertical `50 - 30*C`. Suppressors and approximate source-position fallback additionally reduce C. Head direction and muzzle orientation have modest effects. Terrain/building obstruction reduces both transmission and clarity; smoke is not treated as an acoustic wall. Hearing-provider modifiers, rain, wind, recent competing fire, own fire, fatigue, movement, vehicle interior, and engine masking further affect perception. No full reflection/diffraction or audio-mixer analysis.

Sound arrival is fired-time plus original distance/343. Birth cannot precede arrival. If incoming evidence arrives more than 1.5 s after expected sound arrival, that report is discarded. A currently visible, newly firing source can provide a visual observation; an old explosion never resurrects its firing direction.

## Close confirmation and flash visibility

Current view projection, eye-to-source visibility, camera-to-source visibility where different, distance, sun/NVG mode, and fog gates are required. Thermal alone cannot establish visible-light flash. `checkVisibility` is supplemented with light/distance/fog gates; it cannot provide those itself.

Close confirmation checks head then available upper-body sample for infantry, and the recently captured firing-area offset for vehicles. Require roughly 0.25 s of continuous qualifying observation. Gaps over 0.35 s restart confirmation. Hidden or unknown visibility never counts as clear. Geometry exhaustion fails closed.

Source within 30 m AND confirmed visible dismisses HUNCH over 0.15 s. Use a 35 m release threshold and 0.5 s lost-visibility grace. Fresh incoming evidence is needed to create another cue. Sound/flash observations reference source IDs only in the controller; the renderer never receives source objects. Shot Signal is never called or modified.

## Interfaces and ownership

Production functions live under `HUNCH_fnc_*`; settings and state use `HUNCH_*`.

Shot record hashmap: id, source, sourceId, projectile, original position/direction, fired time, ammo, weapon, muzzle, resolved profile, exact-position flag, and source-local firing offset. Source references stay in detection/confirmation only.

Cue tuple: `[id, kind, immutableDirection, angularUncertainty, confidence, noticeability, RGB, born, expires]`. A tenth field may hold dismissal start. No source-object field.

Optional local provider contract: `HUNCH_contextProviders` contains at most eight CODE values returning `[hearingFactor, maskingFactor, visualAllowed]`. Numeric factors must be finite, clamp to 0–1, and multiply the baseline. Invalid returns use neutral behavior and a diagnostic counter. No automatic unverified third-party hooks. Baseline ACE unconscious state is recognized; optional hearing integrations require verified adapters.

Optional profile overrides: `HUNCH_profileOverrides` hashmap keyed by `str [weaponClass,ammoClass]`, values `[rangeMetres,familyName,flashSupported]`. Keep overrides in the test mission or a separate addon, never in vendor files. Malformed entries are ignored. Providers and overrides must be configured before gameplay; reset/restart after changing profiles.

CBA settings: enabled, color, maximum opacity, size, frequency, ability, flash toggle, close distance, diagnostics. All client-local. Optional keybind starts unassigned. CBA persists preferences; no contacts/observations persist.

## Lifecycle and budgets

Disable entirely in multiplayer. Suspend/clear on invalid/dead/unconscious player, map/menu, spectator or remote camera/control. Rebind on player/vehicle change; clear state on load and mission end. Remove only owned handlers. Saved old projectiles cannot alias new shot IDs after reset.

Perception worker 10 Hz, at most four requests per tick (two under overload). Strict geometry budget 20 calls/s; audio can consume at most 14 to reserve capacity for close confirmation. Optional flash checks run last. Render at most eight picture controls: two per sound cue plus two dots.

Measure event callbacks, worker, and renderer. Sustained over-budget frames degrade optional processing; recover after five seconds below the overload criterion. Targets: average script cost <0.25 ms/frame, p95 <0.5 ms/frame, FPS regression <=2%, p95 total-frame increase <=1 ms. All are acceptance targets pending real Arma measurements.

## Sources

- [Bohemia event handlers](https://community.bistudio.com/wiki/Arma_3%3A_Event_Handlers)
- [Bohemia visibility](https://community.bistudio.com/wiki?title=checkVisibility)
- [Bohemia eye/head direction](https://community.bistudio.com/wiki/eyeDirection)
- [CBA settings](https://cbateam.github.io/CBA_A3/docs/files/settings/fnc_addSetting-sqf.html)
- [SQF-VM runtime](https://github.com/SQFvm/runtime)
