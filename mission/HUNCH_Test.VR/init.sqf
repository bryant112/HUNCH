if (isMultiplayer) exitWith {hint "HUNCH range is single-player only."};
enableSaving [true,true];
HUNCH_testMission = true;
HUNCH_testObjects = [];
HUNCH_testGroups = [];
HUNCH_testStop = true;
HUNCH_testHandle = scriptNull;
HUNCH_testAutoHeal = false;
waitUntil {!isNull player};
player setPosATL [1000,1000,0];
player addEventHandler ["HandleDamage",{
    // Test-only optional invulnerability. Default OFF preserves actual hit behavior.
    if (HUNCH_testAutoHeal) then {0};
}];
HUNCH_test_fnc_clear = {
    HUNCH_testStop = true;
    terminate HUNCH_testHandle;
    {deleteVehicle _x} forEach HUNCH_testObjects;
    {deleteGroup _x} forEach HUNCH_testGroups;
    HUNCH_testObjects = []; HUNCH_testGroups = [];
    if (!isNil "HUNCH_fnc_reset") then {call HUNCH_fnc_reset};
};
HUNCH_test_fnc_start = compile preprocessFileLineNumbers "scenario.sqf";
player addAction ["HUNCH: preview amber spot",{if (!isNil "HUNCH_fnc_preview") then {call HUNCH_fnc_preview}}];
player addAction ["HUNCH: reset settings",{if (!isNil "HUNCH_fnc_resetSettings") then {call HUNCH_fnc_resetSettings}}];
player addAction ["HUNCH: stop and clear range",{call HUNCH_test_fnc_clear}];
player addAction ["HUNCH: toggle test invulnerability",{HUNCH_testAutoHeal = !HUNCH_testAutoHeal; hint format ["Test invulnerability: %1. Use OFF for damage-event acceptance.",HUNCH_testAutoHeal]}];
player addAction ["HUNCH: diagnostics ON",{HUNCH_diagnostics = true}];
player addAction ["HUNCH: day/night",{setDate [2035,6,15,if (daytime > 6) then {0} else {12},0]}];
player addAction ["HUNCH: clear/storm",{private _v = if (rain > 0.1) then {0} else {1}; 0 setOvercast _v; 0 setRain _v; forceWeatherChange}];
{
    _x params ["_title","_family","_distance","_bearing","_count","_cover"];
    player addAction ["HUNCH: " + _title,{(_this select 3) call HUNCH_test_fnc_start},[_family,_distance,_bearing,_count,_cover]];
} forEach [
    ["rifle front 100m","rifle",100,0,1,false],
    ["rifle rear 100m","rifle",100,180,1,false],
    ["close visible 20m","rifle",20,0,1,false],
    ["close behind wall 20m","rifle",20,0,1,true],
    ["rifle visible 80m","rifle",80,0,1,false],
    ["suppressed rifle","suppressed",100,45,1,false],
    ["pistol","pistol",40,0,1,false],
    ["machine gun","mg",150,45,1,false],
    ["heavy machine gun","hmg",250,0,1,false],
    ["launcher","launcher",150,0,1,false],
    ["cannon","cannon",400,0,1,false],
    ["artillery report","artillery",1200,0,1,false],
    ["moderate fire (8 rifles)","rifle",200,0,8,false],
    ["heavy fire (32 rifles)","rifle",200,0,32,false]
];
hint "HUNCH range ready. Live fire can kill you; optional test invulnerability is available. Record hit-event acceptance with it OFF. Diagnostics and previews are in the action menu.";
[] execVM "benchmark.sqf";
