"""Package only this checkout. Compile config, generate a feather texture, verify PBO bytes."""
from pathlib import Path
import hashlib
import json
import shutil
import struct
import subprocess
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(r'C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools')

def guard(path):
    path = path.resolve()
    if 'onedrive' in [s.lower() for s in path.parts] or not path.is_relative_to(ROOT):
        raise ValueError(f'Project destination outside checkout: {path}')
    return path

def read_pbo(path):
    def zstr(f):
        data = bytearray()
        while True:
            b = f.read(1)
            if not b: raise ValueError('Truncated header')
            if b == b'\0': return data.decode('utf-8')
            data.extend(b)
    with path.open('rb') as f:
        entries = []
        while True:
            name = zstr(f)
            method, original, reserved, stamp, size = struct.unpack('<5I', f.read(20))
            if not name and method == 0x56657273:
                while zstr(f): zstr(f)
                continue
            if not name: break
            if method: raise ValueError('Unexpected compression')
            entries.append((name.replace('\\','/').lower(), size))
        result = {}
        for name, size in entries:
            data = f.read(size)
            if len(data) != size: raise ValueError('Truncated payload')
            result[name] = data
        return result

def texture(path):
    # Original mathematical UI mask, generated as uncompressed 32-bit TGA.
    size = 256
    header = struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,size,size,32,0x28)
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            radius = (((x+0.5-size/2)/(size/2))**2 + ((y+0.5-size/2)/(size/2))**2)**0.5
            alpha = round(255 * max(0,1-radius*radius)**2)
            pixels.extend((255,255,255,alpha))
    path.write_bytes(header + pixels)

def package(source, output, prefix, stage_root):
    stage = stage_root / source.name
    shutil.copytree(source, stage)
    if (stage/'config.cpp').exists():
        subprocess.run([str(TOOLS/'CfgConvert/CfgConvert.exe'),'-bin','-dst',str(stage/'config.bin'),str(stage/'config.cpp')],check=True)
        textures = stage/'textures'; textures.mkdir(exist_ok=True)
        texture(textures/'spot_ca.tga')
        subprocess.run([str(TOOLS/'ImageToPAA/ImageToPAA.exe'),str(textures/'spot_ca.tga'),str(textures/'spot_ca.paa')],check=True)
        if not (textures/'spot_ca.paa').is_file(): raise RuntimeError('Texture converter produced no PAA')
        (textures/'spot_ca.tga').unlink()
    packed = stage_root/'packed'; packed.mkdir(exist_ok=True)
    subprocess.run([str(TOOLS/'FileBank/FileBank.exe'),'-property',f'prefix={prefix}','-dst',str(packed),str(stage)],check=True)
    pbo = packed/(source.name+'.pbo')
    entries = read_pbo(pbo)
    expected = {p.relative_to(stage).as_posix().lower(): p.read_bytes() for p in stage.rglob('*') if p.is_file()}
    if entries != expected: raise RuntimeError('PBO readback differs from staged files')
    output.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(pbo,output)
    return {'path':str(output.relative_to(ROOT)),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'entries':len(entries)}

def main():
    guard(ROOT)
    stage = guard(ROOT/'build/staging'/uuid.uuid4().hex); stage.mkdir(parents=True)
    artifacts = [package(ROOT/'addons/hunch',guard(ROOT/'build/@HUNCH/addons/hunch.pbo'),'hunch',stage)]
    artifacts.append(package(ROOT/'mission/HUNCH_Test.VR',guard(ROOT/'build/missions/HUNCH_Test.VR.pbo'),'HUNCH_Test.VR',stage))
    (ROOT/'build/@HUNCH/mod.cpp').write_text('name="HUNCH"; description="Incoming-fire awareness - single-player prototype"; author="HUNCH contributors";\n')
    manifest = {'version':'0.1.0','artifacts':artifacts,'validation':'PBO readback verified; attended runtime acceptance separate'}
    (ROOT/'build/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    archive = ROOT/'build/HUNCH-0.1.0.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for directory,prefix in [(ROOT/'build/@HUNCH','@HUNCH'),(ROOT/'mission/HUNCH_Test.VR','HUNCH_Test.VR'),(ROOT/'docs','docs')]:
            for p in sorted(directory.rglob('*')):
                if p.is_file(): z.write(p,f'{prefix}/{p.relative_to(directory).as_posix()}')
        z.write(ROOT/'README.md','README.md')
        z.write(ROOT/'build/manifest.json','manifest.json')
        z.writestr('INSTALL.txt',
            'HUNCH 0.1.0 - implementation candidate, engine acceptance pending.\n'
            'Extract to a non-OneDrive location such as C:\\dev\\HUNCH-release.\n'
            'Add the extracted @HUNCH folder as a local mod in the Arma launcher, alongside CBA_A3.\n'
            'Use true single-player. Existing Shot Signal can remain enabled independently.\n'
            'HUNCH_Test.VR is a source test mission; it can be opened through its mission.sqm path.\n'
            'The repository README build commands require the development checkout at C:\\dev\\arma-shot-awareness.\n'
            'This portable archive contains the built addon and test mission, not the development tools.\n'
            'Read docs/STATUS.md and docs/ACCEPTANCE.md. No measured performance or visual pass is claimed.\n')
    manifest['archive'] = {'path':str(archive.relative_to(ROOT)),'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
    (ROOT/'build/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(manifest,indent=2))

if __name__ == '__main__': main()
