"""Summarize real HUNCH_BENCH lines. Missing A/B evidence cannot pass a gate."""
from pathlib import Path
import argparse
import json
import re
import statistics

PATTERN = re.compile(r'\[HUNCH_BENCH\] enabled=(true|false) samples=(\d+) mean_ms=([\d.eE+-]+) p95_ms=([\d.eE+-]+) avg_fps=([\d.eE+-]+)',re.I)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('rpt',type=Path,nargs='+')
    args = parser.parse_args()
    rows = []
    for path in args.rpt:
        for match in PATTERN.finditer(path.read_text(errors='replace')):
            enabled,samples,mean,p95,fps = match.groups()
            if int(samples) > 0:
                rows.append({'enabled':enabled.lower()=='true','samples':int(samples),'mean_ms':float(mean),'p95_ms':float(p95),'fps':float(fps),'source':str(path)})
    on = [r for r in rows if r['enabled']]
    off = [r for r in rows if not r['enabled']]
    if len(on)<3 or len(off)<3:
        print(json.dumps({'status':'insufficient evidence','enabled_runs':len(on),'disabled_runs':len(off)},indent=2))
        raise SystemExit(2)
    fps_on = statistics.mean(r['fps'] for r in on)
    fps_off = statistics.mean(r['fps'] for r in off)
    regression = (1-fps_on/fps_off)*100
    increase = statistics.mean(r['p95_ms'] for r in on)-statistics.mean(r['p95_ms'] for r in off)
    passed = regression <= 2 and increase <= 1
    print(json.dumps({'status':'pass' if passed else 'fail','fps_regression_percent':regression,'p95_increase_ms':increase,'runs':rows,'note':'Compare matched scenario files separately. Script-cost gate requires HUNCH_METRIC evidence.'},indent=2))
    raise SystemExit(0 if passed else 1)

if __name__=='__main__': main()
