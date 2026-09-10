{
    _x params ["_name","_value"];
    [_name,_value,0,"client",true] call CBA_settings_fnc_set;
} forEach [
    ["HUNCH_enabled",true],["HUNCH_color",[0.8392,0.6824,0.4078]],
    ["HUNCH_opacity",0.15],["HUNCH_size",1],["HUNCH_frequency",1],
    ["HUNCH_ability",0.5],["HUNCH_flashes",true],["HUNCH_close",30],
    ["HUNCH_diagnostics",false]
];
