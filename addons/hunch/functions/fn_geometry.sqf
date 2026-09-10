/* Shared strict rolling budget. -1 means unavailable; callers must not assume clear. */
params ["_from","_to","_mode",["_ignore",objNull]];
HUNCH_rayTimes = HUNCH_rayTimes select {diag_tickTime - _x < 1};
private _needed = if (_mode == "audio") then {2} else {1};
private _ceiling = if (_mode == "audio") then {14} else {20};
if (count HUNCH_rayTimes + _needed > _ceiling) exitWith {[-1,-1]};
HUNCH_rayTimes pushBack diag_tickTime;
if (_needed == 2) then {HUNCH_rayTimes pushBack diag_tickTime};
private _clear = 0;
if (_mode == "audio") then {
    // Geometry, not VIEW particles: smoke is not an acoustic wall.
    _clear = if (terrainIntersectASL [_from,_to]) then {0} else {
        if (lineIntersects [_from,_to,vehicle player,_ignore]) then {0.45} else {1}
    };
} else {
    _clear = [vehicle player,"VIEW",_ignore] checkVisibility [_from,_to];
};
[_clear,diag_tickTime]
