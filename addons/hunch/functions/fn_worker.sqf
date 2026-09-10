private _start = diag_tickTime;
private _active = call HUNCH_fnc_active;
if (player != HUNCH_player || {vehicle player != HUNCH_vehicle}) then {
    call HUNCH_fnc_reset;
    call HUNCH_fnc_bindReceiver;
};
if (!_active) exitWith {
    if (HUNCH_effective) then {call HUNCH_fnc_reset};
};
HUNCH_effective = true;
HUNCH_noise = HUNCH_noise select {time - _x < 1.5};
HUNCH_context = call HUNCH_fnc_context;
HUNCH_cues = HUNCH_cues select {time < (_x select 8)};
HUNCH_dots = HUNCH_dots select {time < (_x select 8)};
if (time - HUNCH_lastSweep >= 1) then {
    HUNCH_lastSweep = time;
    while {count HUNCH_shotOrder > 0 && {time - ((HUNCH_shotOrder select 0) select 0) > 20}} do {
        HUNCH_shots deleteAt ((HUNCH_shotOrder deleteAt 0) select 1);
    };
    {if (time - (HUNCH_seen get _x) > 20) then {HUNCH_seen deleteAt _x}} forEach keys HUNCH_seen;
    {if (time - ((HUNCH_episodes get _x) get "lastIncoming") > 2) then {HUNCH_episodes deleteAt _x}} forEach keys HUNCH_episodes;
    HUNCH_sources = HUNCH_sources select {!isNull (_x select 0)};
};
private _work = if (HUNCH_degraded) then {2} else {4};
private _flashes = [];
for "_i" from 1 to (_work min count HUNCH_pending) do {
    private _request = HUNCH_pending deleteAt 0;
    _request params ["_key","_received","_kind"];
    private _shot = HUNCH_shots getOrDefault [_key,createHashMap];
    if (count _shot == 0) then {["expired_context"] call HUNCH_fnc_metric} else {
        private _sourceId = _shot get "sourceId";
        private _ep = HUNCH_episodes getOrDefault [_sourceId,createHashMap];
        if (_kind == "flash") then {
            _flashes pushBack [_shot,_ep];
        } else {
            if (time - _received <= 0.5) then {
                if (count _ep == 0) then {
                    if (count HUNCH_episodes >= 32) then {
                        private _old = keys HUNCH_episodes select 0;
                        {if (((HUNCH_episodes get _x) get "lastIncoming") < ((HUNCH_episodes get _old) get "lastIncoming")) then {_old = _x}} forEach keys HUNCH_episodes;
                        HUNCH_episodes deleteAt _old;
                    };
                    _ep = createHashMapFromArray [
                        ["source",_shot get "source"],["lastIncoming",time],["lastAttempt",-100],
                        ["bias",[2 * (call HUNCH_fnc_random) - 1,2 * (call HUNCH_fnc_random) - 1]],
                        ["visibleSince",-1],["lastVisible",-100],["lastCheck",-100],["dismissed",false],
                        ["lastFlash",-100],["cueIds",[]],["shot",_shot]
                    ];
                    HUNCH_episodes set [_sourceId,_ep];
                };
                _ep set ["lastIncoming",time];
                _ep set ["shot",_shot];
                if (_shot get "exact" && {(_shot get "profile") select 3}) then {_flashes pushBack [_shot,_ep]};
                if (!(_ep get "dismissed") && {time - (_ep get "lastAttempt") >= 0.75}) then {
                    _ep set ["lastAttempt",time];
                    private _cue = [_shot,_ep] call HUNCH_fnc_perceive;
                    if (count _cue > 0) then {
                        private _ids = _ep get "cueIds";
                        _ids pushBack (_cue select 0);
                        if (count _ids > 8) then {_ids deleteAt 0};
                        [_cue] call HUNCH_fnc_emit;
                    };
                };
            } else {["stale_queue"] call HUNCH_fnc_metric};
        };
    };
};
// Round-robin close confirmation: bounded to one episode per tick.
private _closeKeys = (keys HUNCH_episodes) select {
    private _src = (HUNCH_episodes get _x) get "source";
    !isNull _src && {_src distance player <= HUNCH_close + 5}
};
if (count _closeKeys > 0) then {
    private _key = _closeKeys select ((floor (time * 10)) % count _closeKeys);
    private _ep = HUNCH_episodes get _key;
    private _source = _ep get "source";
    private _last = _ep get "lastCheck";
    private _position = if (_source isKindOf "CAManBase") then {eyePos _source} else {AGLToASL (_source modelToWorldVisual ((_ep get "shot") get "localPosition"))};
    private _visible = [_position,_source,false] call HUNCH_fnc_visibility;
    if (!_visible && {_source isKindOf "CAManBase"}) then {
        private _chest = AGLToASL (_source modelToWorldVisual (_source selectionPosition "Spine3"));
        if (_chest vectorDistance getPosASL _source > 0.5) then {_visible = [_chest,_source,false] call HUNCH_fnc_visibility};
    };
    _ep set ["lastCheck",time];
    if (_visible) then {
        if ((_ep get "visibleSince") < 0 || {time - _last > 0.35}) then {_ep set ["visibleSince",time]};
        _ep set ["lastVisible",time];
        if (_source distance player <= HUNCH_close && {time - (_ep get "visibleSince") >= 0.25}) then {_ep set ["dismissed",true]};
    } else {_ep set ["visibleSince",-1]};
    if (_source distance player > HUNCH_close + 5 || {time - (_ep get "lastVisible") > 0.5}) then {_ep set ["dismissed",false]};
    if (_ep get "dismissed") then {
        {
            if ((_x select 0) in (_ep get "cueIds") && {count _x == 9}) then {_x pushBack time; _x set [8,time + 0.15]};
        } forEach HUNCH_cues;
        HUNCH_dots = HUNCH_dots select {!((_x select 0) in (_ep get "cueIds"))};
    };
};
// Release dismissal outside hysteresis without needing geometry.
{private _ep = HUNCH_episodes get _x; if ((_ep get "source") distance player > HUNCH_close + 5) then {_ep set ["dismissed",false]}} forEach keys HUNCH_episodes;
// Optional flash geometry runs only after incoming and close-confirmation work.
{
    _x params ["_shot","_ep"];
    if (!HUNCH_degraded && {HUNCH_flashes} && {time - (_shot get "fired") <= 0.12} && {count _ep > 0} && {!(_ep get "dismissed")} && {time - (_ep get "lastFlash") >= 0.75}) then {
        _ep set ["lastFlash",time];
        if ([_shot get "position",_shot get "source",true] call HUNCH_fnc_visibility) then {
            private _key = _shot get "id";
            private _dir = vectorNormalized ((_shot get "position") vectorDiff eyePos player);
            private _ids = _ep get "cueIds"; _ids pushBack _key;
            if (count _ids > 8) then {_ids deleteAt 0};
            [[_key,"flash",_dir,[0,0],1,1,[0,0,0],time,time + 0.15]] call HUNCH_fnc_emit;
        };
    };
} forEach _flashes;
if (HUNCH_diagnostics && {time - HUNCH_lastDiagnostic >= 5}) then {
    HUNCH_lastDiagnostic = time;
    private _costs = +HUNCH_frameCosts;
    _costs sort true;
    private _mean = 0; {_mean = _mean + _x} forEach _costs;
    _mean = _mean / (count _costs max 1);
    private _p95 = if (count _costs > 0) then {_costs select ((floor (0.95 * count _costs)) min (count _costs - 1))} else {0};
    diag_log format ["[HUNCH_METRIC] t=%1 mean_ms=%2 p95_ms=%3 fps=%4 degraded=%5 shots=%6 pending=%7 reasons=%8 context=%9",time,_mean,_p95,diag_fps,HUNCH_degraded,count HUNCH_shots,count HUNCH_pending,HUNCH_metrics,HUNCH_contextReasons];
};
HUNCH_cost = HUNCH_cost + (diag_tickTime - _start) * 1000;
