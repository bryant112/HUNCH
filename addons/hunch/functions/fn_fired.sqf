private _start = diag_tickTime;
_this call {
_this params ["_source","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile",["_gunner",objNull]];
if (!HUNCH_effective || {_weapon in ["Throw","Put"]}) exitWith {};
if (_source == player || {_gunner == player}) exitWith {HUNCH_lastOwn = time};
if (_source distance player > 5000) exitWith {};
private _valid = !isNull _projectile;
private _position = if (_valid) then {getPosASL _projectile} else {getPosASL _source};
private _direction = if (_valid) then {vectorNormalized velocity _projectile} else {vectorDir _source};
private _accessories = if (_source isKindOf "CAManBase") then {_source weaponAccessories _weapon} else {[]};
private _profile = [_weapon,_muzzle,_ammo,_accessories] call HUNCH_fnc_profile;
if (getNumber (configFile >> "CfgVehicles" >> typeOf _source >> "artilleryScanner") > 0) then {
    _profile = +_profile; _profile set [0,5000]; _profile set [1,"artillery"];
};
HUNCH_serial = HUNCH_serial + 1;
private _key = format ["%1:%2",HUNCH_generation,HUNCH_serial];
if (_valid) then {_projectile setVariable ["HUNCH_shotId",_key]};
private _record = createHashMapFromArray [
    ["id",_key],["source",_source],["sourceId",_source getVariable ["HUNCH_sourceId",str _source]],
    ["projectile",_projectile],["position",_position],["direction",_direction],
    ["fired",time],["ammo",_ammo],["weapon",_weapon],["muzzle",_muzzle],
    ["profile",_profile],["exact",_valid],
    ["localPosition",_source worldToModel (ASLToAGL _position)]
];
HUNCH_shots set [_key,_record];
HUNCH_shotOrder pushBack [time,_key];
if (count HUNCH_shotOrder > 2048) then {HUNCH_shots deleteAt ((HUNCH_shotOrder deleteAt 0) select 1); ["shot_eviction"] call HUNCH_fnc_metric};
if (_source distance player < 300) then {HUNCH_noise pushBack time; if (count HUNCH_noise > 32) then {HUNCH_noise deleteAt 0}};
// A flash may only be evaluated for a source already confirmed incoming recently.
private _episode = HUNCH_episodes getOrDefault [_record get "sourceId",createHashMap];
if (HUNCH_flashes && {!HUNCH_degraded} && {count _episode > 0} && {time - (_episode get "lastIncoming") <= 2} && {_valid} && {_profile select 3}) then {
    if (count HUNCH_pending < 32) then {HUNCH_pending pushBack [_key,time,"flash"]};
};
 ["fired"] call HUNCH_fnc_metric;
};
HUNCH_cost = HUNCH_cost + (diag_tickTime - _start) * 1000;
