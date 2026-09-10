disableSerialization;
private _start = diag_tickTime;
private _display = uiNamespace getVariable ["HUNCH_display",displayNull];
if (HUNCH_effective && {isNull _display}) then {
    ("HUNCH_layer" call BIS_fnc_rscLayer) cutRsc ["HUNCH_Overlay","PLAIN"];
    _display = uiNamespace getVariable ["HUNCH_display",displayNull];
};
if (!isNull _display) then {
    if (HUNCH_controlDisplay != _display) then {
        {ctrlDelete _x} forEach HUNCH_controls;
        HUNCH_controls = [];
        for "_i" from 0 to 7 do {
            private _ctrl = _display ctrlCreate ["RscPicture",-1];
            _ctrl ctrlEnable false;
            _ctrl ctrlSetText "\hunch\textures\spot_ca.paa";
            HUNCH_controls pushBack _ctrl;
        };
        HUNCH_controlDisplay = _display;
    };
    { _x ctrlShow false } forEach HUNCH_controls;
    if (HUNCH_effective && {!visibleMap} && {!dialog} && {isNull findDisplay 49}) then {
        private _items = (HUNCH_cues + HUNCH_dots) select {time >= (_x select 7) && {time < (_x select 8)}};
        private _cap = HUNCH_opacity min 0.4 max 0;
        private _alphas = _items apply {
            private _flash = (_x select 1) == "flash";
            private _fade = [time - (_x select 7),if (_flash) then {0.15} else {1.2}] call HUNCH_fnc_envelope;
            if (count _x > 9) then {_fade = _fade * ((1 - (time - (_x select 9)) / 0.15) max 0)};
            (if (_flash) then {0.4} else {_cap * (_x select 4)}) * _fade
        };
        // Global sum is conservative but guarantees alpha safety under every overlap.
        private _soundIndices = []; private _soundAlphas = [];
        {if ((_x select 1) == "sound") then {_soundIndices pushBack _forEachIndex; _soundAlphas pushBack (_alphas select _forEachIndex)}} forEach _items;
        private _soundBudget = [_soundAlphas,_cap] call HUNCH_fnc_alphaBudget;
        {_alphas set [_x,_soundBudget select _forEachIndex]} forEach _soundIndices;
        _alphas = [_alphas,0.4] call HUNCH_fnc_alphaBudget;
        private _camera = positionCameraToWorld [0,0,0];
        private _forward = vectorNormalized ((positionCameraToWorld [0,0,1]) vectorDiff _camera);
        private _right = vectorNormalized ((positionCameraToWorld [1,0,0]) vectorDiff _camera);
        private _up = vectorNormalized ((positionCameraToWorld [0,1,0]) vectorDiff _camera);
        private _slot = 0;
        {
            _x params ["_id","_kind","_dir","_uncertainty","_confidence","_notice","_color"];
            private _flash = _kind == "flash";
            private _screen = worldToScreen (_camera vectorAdd (_dir vectorMultiply 1000));
            private _h = if (_flash) then {(3 * ((getResolution select 1) / 1080) max 2 min 6) * pixelH} else {(0.55 - 0.2 * _confidence) * safeZoneH * HUNCH_size};
            private _w = _h * pixelW / pixelH;
            private _normalized = if (count _screen == 2) then {[((_screen select 0) - safeZoneX) / safeZoneW,((_screen select 1) - safeZoneY) / safeZoneH]} else {[]};
            private _layout = [_normalized,[_dir vectorDotProduct _right,_dir vectorDotProduct _up,_dir vectorDotProduct _forward],[_w/safeZoneW,_h/safeZoneH]] call HUNCH_fnc_layout;
            _layout params ["_inside","_mix","_edge"];
            if (!_flash || {_inside}) then {
                private _brightness = if (_flash) then {0} else {0.55 + 0.45 * _notice};
                private _alpha = _alphas select _forEachIndex;
                if (_flash) then {_mix = 0};
                if (_inside && {_mix < 1}) then {
                    private _ctrl = HUNCH_controls select _slot; _slot = _slot + 1;
                    _ctrl ctrlSetTextColor [(_color select 0)*_brightness,(_color select 1)*_brightness,(_color select 2)*_brightness,_alpha*(1-_mix)];
                    _ctrl ctrlSetPosition [(_screen select 0)-_w/2,(_screen select 1)-_h/2,_w,_h];
                    _ctrl ctrlCommit 0; _ctrl ctrlShow true;
                };
                if (!_flash && {_mix > 0}) then {
                    private _cx = safeZoneX + (_edge select 0) * safeZoneW;
                    private _cy = safeZoneY + (_edge select 1) * safeZoneH;
                    if (abs ((_edge select 0)-0.5) >= 0.49) then {_w = 0.12*safeZoneH*pixelW/pixelH} else {_h = 0.12*safeZoneH};
                    private _ctrl = HUNCH_controls select _slot; _slot = _slot + 1;
                    _ctrl ctrlSetTextColor [(_color select 0)*_brightness,(_color select 1)*_brightness,(_color select 2)*_brightness,_alpha*_mix];
                    _ctrl ctrlSetPosition [_cx-_w/2,_cy-_h/2,_w,_h];
                    _ctrl ctrlCommit 0; _ctrl ctrlShow true;
                };
            };
        } forEach _items;
    };
};
private _total = HUNCH_cost + (diag_tickTime - _start) * 1000;
HUNCH_cost = 0;
HUNCH_frameCosts pushBack _total;
if (count HUNCH_frameCosts > 600) then {HUNCH_frameCosts deleteAt 0};
if (_total > 0.5) then {HUNCH_overBudgetFrames = HUNCH_overBudgetFrames + 1} else {HUNCH_overBudgetFrames = (HUNCH_overBudgetFrames - 0.1) max 0};
if (HUNCH_overBudgetFrames >= 5) then {HUNCH_degraded = true; HUNCH_recoverAt = -1} else {
    if (HUNCH_degraded) then {
        if (HUNCH_recoverAt < 0) then {HUNCH_recoverAt = diag_tickTime};
        if (diag_tickTime - HUNCH_recoverAt > 5) then {HUNCH_degraded = false};
    };
};
