/* Provider contract: CODE returning [hearing 0..1, masking 0..1, visualAllowed BOOL]. */
private _hearing = 1;
private _mask = 1;
private _visual = (currentVisionMode player) != 2;
{
    private _value = if (_x isEqualType {}) then {try {call _x} catch {[]}} else {[]};
    if (_value isEqualType [] && {count _value == 3} && {(_value select 0) isEqualType 0} && {(_value select 1) isEqualType 0} && {(_value select 2) isEqualType true} && {finite (_value select 0)} && {finite (_value select 1)}) then {
        _hearing = _hearing * ([_value select 0] call HUNCH_fnc_clamp);
        _mask = _mask * ([_value select 1] call HUNCH_fnc_clamp);
        _visual = _visual && {_value select 2};
    } else {["invalid_context_provider"] call HUNCH_fnc_metric};
} forEach (HUNCH_contextProviders select [0,8]);
HUNCH_contextReasons = [];
if (rain > 0.1) then {HUNCH_contextReasons pushBack "rain"};
if (vectorMagnitude wind > 3) then {HUNCH_contextReasons pushBack "wind"};
if (count HUNCH_noise > 0) then {HUNCH_contextReasons pushBack "competing_fire"};
if (time - HUNCH_lastOwn < 1.5) then {HUNCH_contextReasons pushBack "own_fire"};
if (vehicle player != player) then {HUNCH_contextReasons pushBack "vehicle"};
if (getFatigue player > 0.2) then {HUNCH_contextReasons pushBack "fatigue"};
if (abs speed player > 3) then {HUNCH_contextReasons pushBack "movement"};
if (_hearing < 1 || {_mask < 1}) then {HUNCH_contextReasons pushBack "hearing_provider"};
_mask = _mask * (1 - 0.25 * rain) * (1 - 0.2 * ((vectorMagnitude wind / 20) min 1));
_mask = _mask * (1 - 0.45 * (((count HUNCH_noise) / 12) min 1));
if (time - HUNCH_lastOwn < 1.5) then {_mask = _mask * 0.35};
private _attention = (1 - 0.15 * getFatigue player) * (1 - 0.15 * ((abs speed player / 18) min 1));
if (vehicle player != player) then {
    if (!isTurnedOut player) then {_mask = _mask * 0.55};
    if (isEngineOn vehicle player) then {_mask = _mask * 0.6};
};
[_hearing,_mask,_attention,_visual]
