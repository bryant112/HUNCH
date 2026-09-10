/* Only HUNCH settings persist. CBA owns profile persistence. */
["HUNCH_enabled","CHECKBOX",["Enabled","True single-player only"],"HUNCH",true,0] call CBA_fnc_addSetting;
["HUNCH_color","COLOR","Impression color","HUNCH",[0.8392,0.6824,0.4078],0] call CBA_fnc_addSetting;
["HUNCH_opacity","SLIDER",["Maximum opacity","Shared by overlapping HUNCH impressions"],"HUNCH",[0.05,0.4,0.15,2,true],0] call CBA_fnc_addSetting;
["HUNCH_size","SLIDER","Spot size","HUNCH",[0.5,1.5,1,2],0] call CBA_fnc_addSetting;
["HUNCH_frequency","SLIDER","Cue frequency","HUNCH",[0,2,1,2],0] call CBA_fnc_addSetting;
["HUNCH_ability","SLIDER","Perception ability","HUNCH",[0,1,0.5,2],0] call CBA_fnc_addSetting;
["HUNCH_flashes","CHECKBOX","Muzzle-flash dots","HUNCH",true,0] call CBA_fnc_addSetting;
["HUNCH_close","SLIDER","Close and clearly seen distance (m)","HUNCH",[5,100,30,0],0] call CBA_fnc_addSetting;
["HUNCH_diagnostics","CHECKBOX","Diagnostics (RPT timings and reasons)","HUNCH",false,0] call CBA_fnc_addSetting;
["HUNCH","toggle","Toggle HUNCH",{HUNCH_enabled = !HUNCH_enabled},{},[0,[false,false,false]]] call CBA_fnc_addKeybind;
