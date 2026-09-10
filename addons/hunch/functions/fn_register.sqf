params ["_entity"];
if (isNull _entity || {!local _entity}) exitWith {};
if (!(_entity isKindOf "CAManBase" || {_entity isKindOf "LandVehicle"} || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"})) exitWith {};
if (_entity getVariable ["HUNCH_registered",false]) exitWith {};
private _id = _entity addEventHandler ["Fired",{_this call HUNCH_fnc_fired}];
HUNCH_entitySequence = HUNCH_entitySequence + 1;
_entity setVariable ["HUNCH_sourceId",str HUNCH_entitySequence];
_entity setVariable ["HUNCH_registered",true];
HUNCH_sources pushBack [_entity,"Fired",_id];
