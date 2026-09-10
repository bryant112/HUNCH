{_x params ["_obj","_event","_id"]; if (!isNull _obj) then {_obj removeEventHandler [_event,_id]}} forEach HUNCH_receiverEH;
HUNCH_receiverEH = [];
HUNCH_player = player;
HUNCH_vehicle = vehicle player;
if (isNull player) exitWith {};
private _receivers = [player];
_receivers pushBackUnique HUNCH_vehicle;
{
    private _object = _x;
    private _id = _object addEventHandler ["Suppressed",{
        _this params ["_receiver","_distance","_source","_instigator","_projectile","_ammo"];
        [_source,_projectile,_ammo,"near",_instigator] call HUNCH_fnc_incoming;
    }];
    HUNCH_receiverEH pushBack [_object,"Suppressed",_id];
    _id = _object addEventHandler ["HitPart",{
        {
            _x params ["_target","_source","_projectile","_position","_velocity","_selection","_ammo","_vector","_radius","_surface","_direct"];
            if (count _ammo >= 5) then {
                [_source,_projectile,_ammo select 4,if (_direct) then {"hit"} else {"splash"},_x param [11,objNull]] call HUNCH_fnc_incoming;
            };
        } forEach _this;
    }];
    HUNCH_receiverEH pushBack [_object,"HitPart",_id];
    _id = _object addEventHandler ["IncomingMissile",{
        _this params ["_target","_ammo","_source","_instigator","_projectile"];
        [_source,_projectile,_ammo,"missile",_instigator] call HUNCH_fnc_incoming;
    }];
    HUNCH_receiverEH pushBack [_object,"IncomingMissile",_id];
} forEach _receivers;
