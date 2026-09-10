private _start = diag_tickTime;
_this call {
params ["_source","_projectile","_ammo","_kind",["_instigator",objNull]];
if (!HUNCH_effective || {_source == player} || {_instigator == player}) exitWith {};
private _key = if (isNull _projectile) then {""} else {_projectile getVariable ["HUNCH_shotId",""]};
// Never guess a firing location from current shooter position or ambiguous source/ammo matching.
if (_key == "") exitWith {["missing_shot_context"] call HUNCH_fnc_metric};
if (_key in HUNCH_seen) exitWith {["duplicate"] call HUNCH_fnc_metric};
if (count HUNCH_pending >= 32) exitWith {["queue_full"] call HUNCH_fnc_metric};
HUNCH_seen set [_key,time];
HUNCH_pending pushBack [_key,time,_kind];
["incoming"] call HUNCH_fnc_metric;
};
HUNCH_cost = HUNCH_cost + (diag_tickTime - _start) * 1000;
