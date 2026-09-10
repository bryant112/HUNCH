params ["_position","_source",["_flash",false]];
if (!(HUNCH_context select 3) || {isNull _source}) exitWith {false};
private _distance = (eyePos player) vectorDistance _position;
if (_distance > (if (_flash) then {250} else {100})) exitWith {false};
private _screen = worldToScreen (ASLToAGL _position);
if (count _screen != 2) exitWith {false};
if ((_screen select 0) < safeZoneX || {(_screen select 0) > safeZoneX + safeZoneW} || {(_screen select 1) < safeZoneY} || {(_screen select 1) > safeZoneY + safeZoneH}) exitWith {false};
private _light = sunOrMoon;
if (currentVisionMode player == 1) then {_light = _light max 0.5};
if (!_flash && {_light < 0.15}) exitWith {false};
if (fog * _distance > (if (_flash) then {60} else {20})) exitWith {false};
private _ignore = if (_flash || {!(_source isKindOf "CAManBase")}) then {objNull} else {_source};
private _eye = [eyePos player,_position,"visual",_ignore] call HUNCH_fnc_geometry;
if ((_eye select 0) < 0.8) exitWith {false};
private _camera = AGLToASL (positionCameraToWorld [0,0,0]);
if (_camera vectorDistance eyePos player > 0.5) exitWith {
    (([_camera,_position,"visual",_ignore] call HUNCH_fnc_geometry) select 0) >= 0.8
};
true
