/* Engine-independent production functions. Angles are degrees, simulation times seconds. */
HUNCH_fnc_clamp = {params ["_x",["_low",0],["_high",1]]; (_x max _low) min _high};
HUNCH_fnc_score = {
    params ["_distance","_range","_acoustic","_mask","_attention","_clarity","_ability","_frequency"];
    private _n = if (_range <= 0) then {0} else {[((1 - _distance / (_range max 1)) max 0) * _acoustic * _mask * _attention] call HUNCH_fnc_clamp};
    private _p = [(_frequency * _n * (0.6 + 0.4 * _ability)),0,0.85] call HUNCH_fnc_clamp;
    private _c = [_n * (0.55 + 0.45 * _ability) * _clarity,0,0.85] call HUNCH_fnc_clamp;
    [_n,_c,_p,60 - 48 * _c,50 - 30 * _c]
};
HUNCH_fnc_envelope = {
    params ["_age",["_duration",1.2]];
    if (_age < 0 || {_age >= _duration}) exitWith {0};
    if (_duration <= 0.15) exitWith {1 - _age / _duration};
    if (_age < 0.15) exitWith {_age / 0.15};
    if (_age <= 0.35) exitWith {1};
    ((_duration - _age) / (_duration - 0.35)) max 0
};
HUNCH_fnc_alphaBudget = {
    params ["_alphas","_cap"];
    private _sum = 0; {_sum = _sum + _x} forEach _alphas;
    private _scale = if (_sum > _cap) then {_cap / _sum} else {1};
    _alphas apply {_x * _scale}
};
HUNCH_fnc_audioWindow = {
    params ["_fired","_distance","_now"];
    private _arrival = _fired + _distance / 343;
    [_arrival,_now <= _arrival + 1.5]
};
HUNCH_fnc_angleDelta = {params ["_a","_b"]; ((_a - _b + 540) % 360) - 180};
HUNCH_fnc_direction = {
    params ["_bearing","_elevation"];
    [sin _bearing * cos _elevation,cos _bearing * cos _elevation,sin _elevation]
};
HUNCH_fnc_random = {
    // Local Park-Miller generator; never changes mission/global random state.
    HUNCH_seed = (HUNCH_seed * 16807) % 2147483647;
    HUNCH_seed / 2147483647
};
HUNCH_fnc_layout = {
    params ["_screen","_localDirection","_diameter"];
    private _hasScreen = count _screen == 2;
    private _inside = _hasScreen && {(_screen select 0) >= 0} && {(_screen select 0) <= 1} && {(_screen select 1) >= 0} && {(_screen select 1) <= 1};
    private _edge = [0.5,1];
    private _mix = 1;
    if (_hasScreen && {(_localDirection select 2) > 0}) then {
        private _sx = _screen select 0; private _sy = _screen select 1;
        private _dx = _sx - 0.5; private _dy = _sy - 0.5;
        private _scale = (abs _dx max abs _dy) max 0.0001;
        _edge = [0.5 + 0.5 * _dx / _scale,0.5 + 0.5 * _dy / _scale];
        if (_inside) then {
            private _room = ((_sx min (1 - _sx)) / ((_diameter select 0) / 2)) min ((_sy min (1 - _sy)) / ((_diameter select 1) / 2));
            _mix = [1 - _room] call HUNCH_fnc_clamp;
        };
    } else {
        private _horizontal = _localDirection select 0;
        private _vertical = -(_localDirection select 1);
        if ((_localDirection select 2) < 0) then {_vertical = (abs _vertical) max (0.5 * (1 - abs _horizontal))};
        private _scale = (abs _horizontal max abs _vertical) max 0.001;
        _edge = [0.5 + _horizontal / _scale / 2,0.5 + _vertical / _scale / 2];
    };
    [_inside,_mix,_edge]
};
