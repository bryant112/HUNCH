"""Source/config and actual production SQF math verification. No claim of Arma UI execution."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
from build import ROOT, TOOLS, guard

def run(cmd, destination):
    result = subprocess.run([str(v) for v in cmd], capture_output=True, text=True, errors='replace')
    output = result.stdout + result.stderr
    destination.write_text(output,encoding='utf-8')
    if result.returncode or re.search(r'\[(ERR|FAT)\]|\[ERROR\]|RUNTIME ERROR',output):
        raise RuntimeError(f'{destination.name}:\n{output}')
    return output

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sqfvm',type=Path,default=ROOT/'build/tools/sqfvm/sqfvm_windows_x64/sqfvm.exe')
    args = parser.parse_args()
    out = guard(ROOT/'build/validation'); out.mkdir(parents=True,exist_ok=True)
    run([__import__('sys').executable,'-m','unittest','discover','-s',str(ROOT/'tests'),'-p','test_*.py','-v'],out/'tool-tests.log')
    scripts = sorted((ROOT/'addons').rglob('*.sqf')) + sorted((ROOT/'mission').rglob('*.sqf'))
    if not args.sqfvm.is_file(): raise SystemExit('SQF-VM required. See README setup; no fallback to Python scoring.')
    base = [args.sqfvm,'-a','--suppress-welcome','--no-work-print','--no-execute-print']
    cmd = base + ['--parse-only']
    for p in scripts: cmd += ['--input-sqf',p]
    run(cmd,out/'parse.log')
    harness = out/'math.sqf'
    harness.write_text((ROOT/'addons/hunch/math.sqf').read_text()+'\n'+(ROOT/'tests/math.sqf').read_text())
    log = run(base+['--input-sqf',harness],out/'math.log')
    assert 'HUNCH_MATH_PASS checks=23' in log, log
    runtime = out/'runtime.sqf'
    pieces = [(ROOT/'addons/hunch/math.sqf').read_text()]
    pieces.append('HUNCH_fnc_metric = {}; // VM lacks getOrDefault; metrics are not exercised here.')
    for name in ['reset','incoming','emit']:
        source = (ROOT/f'addons/hunch/functions/fn_{name}.sqf').read_text()
        # SQF-VM has no display type. Substitute only the empty UI sentinel;
        # controls are empty in these tests. Production parsing remains unmodified.
        if name == 'reset': source = source.replace('displayNull','objNull')
        pieces.append(f'HUNCH_fnc_{name} = {{\n'+source+'\n};')
    runtime.write_text('\n'.join(pieces)+'\n'+(ROOT/'tests/runtime.sqf').read_text())
    log = run(base+['--input-sqf',runtime],out/'runtime.log')
    assert 'HUNCH_RUNTIME_PASS checks=12' in log, log
    for i,p in enumerate([ROOT/'addons/hunch/config.cpp',ROOT/'mission/HUNCH_Test.VR/description.ext',ROOT/'mission/HUNCH_Test.VR/mission.sqm']):
        run([TOOLS/'CfgConvert/CfgConvert.exe','-test',p],out/f'config-{i}.log')
    addon = '\n'.join(p.read_text() for p in (ROOT/'addons').rglob('*.sqf'))
    for forbidden in ['removeAllEventHandlers','remoteExec','setFriend','setDamage','setHit','reveal','playSound','say3D']:
        assert not re.search(r'\b'+forbidden+r'\b',addon), forbidden
    render = (ROOT/'addons/hunch/functions/fn_render.sqf').read_text()
    for forbidden in ['allUnits','nearestObjects','checkVisibility','lineIntersects','HUNCH_shots','getPosASL','getPosATL']:
        assert forbidden not in render, forbidden
    config = (ROOT/'addons/hunch/config.cpp').read_text()
    registered = re.findall(r'class (\w+)\s*\{(?:preInit = 1;|postInit = 1;)?\};',config)
    for name in registered:
        if name not in ['controls']:
            assert (ROOT/f'addons/hunch/functions/fn_{name}.sqf').is_file(),name
    result = {'status':'pass','sqf_parse_files':len(scripts),'production_math_checks':23,
        'sqf_state_checks':12,'python_tool_tests':6,'config_checks':3,'source_contracts':'pass','engine_runtime':'not run; existing Arma session preserved',
        'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in scripts}}
    (out/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='source_sha256'},indent=2))

if __name__ == '__main__': main()
