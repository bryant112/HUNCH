// Explicit test-mission action only; cannot be triggered by an incoming event.
if (!(missionNamespace getVariable ["HUNCH_testMission",false])) exitWith {};
private _bearing = getDir player;
private _cue = ["preview","sound",[_bearing + 25,0] call HUNCH_fnc_direction,[40,30],0.7,0.9,+HUNCH_color,time,time + 1.2];
[_cue] call HUNCH_fnc_emit;
