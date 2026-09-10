params ["_family","_distance","_bearing","_count","_cover"];
call HUNCH_test_fnc_clear;
player setDamage 0;
player setPosATL [1000,1000,0];
player setDir 0;
HUNCH_testStop = false;
for "_i" from 0 to (_count - 1) do {
    private _angle = _bearing + (if (_count > 1) then {_i * 360 / _count} else {0});
    private _position = [1000 + sin _angle * _distance,1000 + cos _angle * _distance,0];
    private _group = createGroup [east,true];
    HUNCH_testGroups pushBack _group;
    private _unit = _group createUnit ["O_Soldier_F",_position,[],0,"NONE"];
    HUNCH_testObjects pushBack _unit;
    _unit setSkill 0.4;
    _unit disableAI "PATH";
    _unit setUnitPos "UP";
    removeAllWeapons _unit;
    private _weapon = "arifle_Katiba_F";
    private _magazine = "30Rnd_65x39_caseless_green";
    switch (_family) do {
        case "pistol": {_weapon = "hgun_Rook40_F"; _magazine = "16Rnd_9x21_Mag"};
        case "mg": {_weapon = "LMG_Zafir_F"; _magazine = "150Rnd_762x54_Box"};
        case "launcher": {_weapon = "launch_RPG32_F"; _magazine = "RPG32_F"};
    };
    for "_j" from 1 to 12 do {_unit addMagazine _magazine};
    _unit addWeapon _weapon;
    if (_family == "suppressed") then {_unit addPrimaryWeaponItem "muzzle_snds_H"};
    if (_family in ["hmg","cannon","artillery"]) then {
        private _type = switch (_family) do {case "hmg": {"O_HMG_01_high_F"}; case "cannon": {"O_MBT_02_cannon_F"}; default {"O_Mortar_01_F"}};
        private _vehicle = createVehicle [_type,_position,[],0,"NONE"];
        HUNCH_testObjects pushBack _vehicle;
        _unit moveInGunner _vehicle;
        _vehicle setDir (_vehicle getDir player);
    };
    _unit reveal [player,4];
    _unit doTarget player;
    _unit doFire player;
    if (_family == "artillery") then {(vehicle _unit) doArtilleryFire [getPosATL player,"8Rnd_82mm_Mo_shells",3]};
};
if (_cover) then {
    private _wall = createVehicle ["Land_CncWall4_F",[1000,1010,0],[],0,"NONE"];
    HUNCH_testObjects pushBack _wall;
};
diag_log format ["[HUNCH_SCENARIO] family=%1 distance=%2 bearing=%3 count=%4 cover=%5",_family,_distance,_bearing,_count,_cover];
HUNCH_testHandle = [] spawn {
    while {!HUNCH_testStop} do {
        {if (_x isKindOf "CAManBase" && {alive _x}) then {_x doTarget player; _x doFire player; (vehicle _x) setVehicleAmmo 1}} forEach HUNCH_testObjects;
        sleep 3;
    };
};
