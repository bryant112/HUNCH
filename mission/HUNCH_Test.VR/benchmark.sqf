// Captures total frame times even when HUNCH is not loaded. Start manually after warmup.
HUNCH_benchmark = [];
HUNCH_benchmarkUntil = -1;
HUNCH_benchmarkLast = diag_tickTime;
addMissionEventHandler ["EachFrame",{
    private _now = diag_tickTime;
    if (_now < HUNCH_benchmarkUntil) then {HUNCH_benchmark pushBack ((_now - HUNCH_benchmarkLast) * 1000)};
    HUNCH_benchmarkLast = _now;
}];
player addAction ["HUNCH: capture 120-second benchmark",{
    if (diag_tickTime < HUNCH_benchmarkUntil) exitWith {hint "Benchmark already recording"};
    HUNCH_benchmark = [];
    HUNCH_benchmarkUntil = diag_tickTime + 120;
    [] spawn {
        sleep 121;
        private _samples = +HUNCH_benchmark;
        _samples sort true;
        private _sum = 0; {_sum = _sum + _x} forEach _samples;
        private _mean = _sum / (count _samples max 1);
        private _p95 = _samples param [((floor (count _samples * 0.95)) min (count _samples - 1)),0];
        diag_log format ["[HUNCH_BENCH] enabled=%1 samples=%2 mean_ms=%3 p95_ms=%4 avg_fps=%5",missionNamespace getVariable ["HUNCH_enabled",false],count _samples,_mean,_p95,1000 / (_mean max 0.001)];
        hint "Benchmark written to this test profile's RPT.";
    };
}];
