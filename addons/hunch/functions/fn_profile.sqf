params ["_weapon","_muzzle","_ammo","_accessories"];
private _cacheKey = str [_weapon,_muzzle,_ammo,_accessories];
private _cached = HUNCH_profiles getOrDefault [_cacheKey,[]];
if (count _cached > 0) exitWith {_cached};
private _wc = configFile >> "CfgWeapons" >> _weapon;
private _ac = configFile >> "CfgAmmo" >> _ammo;
private _simulation = toLower getText (_ac >> "simulation");
private _family = "unknown";
private _range = 600;
private _typical = getNumber (_ac >> "typicalSpeed");
private _caliber = getNumber (_ac >> "caliber");
switch (_simulation) do {
    case "shotbullet": {
        _family = "rifle"; _range = 1000;
        if (_weapon isKindOf ["Pistol",configFile >> "CfgWeapons"] || {_weapon isKindOf ["SMG_01_base",configFile >> "CfgWeapons"]} || {_weapon isKindOf ["SMG_02_base",configFile >> "CfgWeapons"]}) then {_family = "pistol_smg"; _range = 400};
        if (_caliber >= 2.5) then {_family = "heavy_mg"; _range = 1800};
    };
    case "shotshell": {_family = "cannon"; _range = 3000};
    case "shotrocket": {_family = "launcher"; _range = 1500};
    case "shotmissile": {_family = "launcher"; _range = 1500};
};
if (getNumber (_wc >> "artilleryScanner") > 0) then {_family = "artillery"; _range = 5000};
private _silencer = _accessories param [0,""];
private _suppressed = _silencer != "";
private _flash = false; // Unknown flash configuration deliberately fails closed.
private _effect = getText (_ac >> "muzzleEffect");
private _muzzleCfg = if (_muzzle == _weapon) then {_wc} else {_wc >> _muzzle};
if (_effect != "" || {isClass (_muzzleCfg >> "GunParticles")}) then {_flash = true};
private _modifier = 1;
if (_suppressed) then {
    private _coef = configFile >> "CfgWeapons" >> _silencer >> "ItemInfo" >> "AmmoCoef";
    _modifier = if (isNumber (_coef >> "audibleFire")) then {[(getNumber (_coef >> "audibleFire")),0.05,1] call HUNCH_fnc_clamp} else {0.25};
    _flash = false;
};
// Explicit project-owned overrides: [range, family, flashSupported]. No vendor writes.
private _override = (missionNamespace getVariable ["HUNCH_profileOverrides",createHashMap]) getOrDefault [str [_weapon,_ammo],[]];
if (_override isEqualType [] && {count _override == 3} && {(_override select 0) isEqualType 0} && {finite (_override select 0)} && {(_override select 1) isEqualType ""} && {(_override select 2) isEqualType true}) then {
    _range = (_override select 0) max 1 min 5000; _family = _override select 1; _flash = (_override select 2) && {!_suppressed};
};
private _result = [_range * _modifier,_family,_suppressed,_flash,_typical];
if (count HUNCH_profiles >= 512) then {HUNCH_profiles = createHashMap};
HUNCH_profiles set [_cacheKey,_result];
_result
