params ["_cue"];
if (count _cue == 0) exitWith {};
if ((_cue select 1) == "flash") exitWith {
    if (count HUNCH_dots < 2) then {HUNCH_dots pushBack _cue; ["flash_emitted"] call HUNCH_fnc_metric};
};
HUNCH_rates = HUNCH_rates select {time - _x < 1};
if (count HUNCH_rates >= 2) exitWith {["visual_rate_limit"] call HUNCH_fnc_metric};
// Retain one existing bearing; never average multiple observations into an exact position.
private _overlap = HUNCH_cues findIf {((_x select 2) vectorDotProduct (_cue select 2)) > cos 25};
if (_overlap >= 0) then {
    if ((_cue select 5) > ((HUNCH_cues select _overlap) select 5)) then {HUNCH_cues set [_overlap,_cue]};
} else {
    if (count HUNCH_cues < 3) then {HUNCH_cues pushBack _cue} else {
        private _weak = 0;
        for "_i" from 1 to 2 do {if (((HUNCH_cues select _i) select 5) < ((HUNCH_cues select _weak) select 5)) then {_weak = _i}};
        if ((_cue select 5) > ((HUNCH_cues select _weak) select 5)) then {HUNCH_cues set [_weak,_cue]};
    };
};
HUNCH_rates pushBack time;
["sound_emitted"] call HUNCH_fnc_metric;
