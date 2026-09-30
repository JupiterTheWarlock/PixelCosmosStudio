"""Check rendered seam probes and the structure of exported GLBs. Requires Pillow."""
from pathlib import Path
import json
import struct
from PIL import Image, ImageChops

root = Path(__file__).resolve().parents[1] / 'exports/v2'
faces = ['px', 'nx', 'py', 'ny', 'pz', 'nz']

def direction(face, x, y, size):
    u, v = 2*x/(size-1)-1, 2*y/(size-1)-1
    return [(1,-v,-u),(-1,-v,u),(u,1,v),(u,-1,-v),(u,-v,1),(-u,-v,-1)][face]

samples = {}
for face, name in enumerate(faces):
    image = Image.open(root / f'edge_{name}.png').convert('RGBA')
    size = image.width
    for y in range(size):
        for x in range(size):
            if x not in (0,size-1) and y not in (0,size-1):
                continue
            key = tuple(round(c, 7) for c in direction(face,x,y,size))
            samples.setdefault(key, []).append(image.getpixel((x,y)))
assert all(len(values) in (2,3) for values in samples.values())
max_delta = max(max(abs(a-b) for a,b in zip(values[0],other))
                for values in samples.values() for other in values[1:])
bad = sum(any(max(abs(a-b) for a,b in zip(values[0],other)) > 1
              for other in values[1:]) for values in samples.values())
assert bad == 0, f'Seam discontinuity: {bad} samples; max channel delta {max_delta}'

models = {}
for name in ['planet','voxel']+[f'type_{i}' for i in range(8)]:
    raw=(root/name/'planet.glb').read_bytes()
    magic,version,length=struct.unpack_from('<4sII',raw)
    assert magic==b'glTF' and version==2 and length==len(raw)
    chunk_len,chunk_type=struct.unpack_from('<II',raw,12)
    assert chunk_type==0x4e4f534a
    data=json.loads(raw[20:20+chunk_len])
    assert 'KHR_lights_punctual' not in data.get('extensions',{})
    primitives=[p for mesh in data['meshes'] for p in mesh['primitives']]
    assert primitives and all('NORMAL' in p['attributes'] for p in primitives)
    assert all('KHR_materials_unlit' not in m.get('extensions',{}) for m in data['materials'])
    assert all('pbrMetallicRoughness' in m for m in data['materials'])
    if name=='voxel':
        assert any('COLOR_0' in p['attributes'] for p in primitives)
    assert all(s.get('magFilter')==9728 for s in data.get('samplers',[]))
    models[name]={'primitives':len(primitives),'bytes':len(raw)}

for name in (root/'planet').glob('*.png'):
    assert name.read_bytes()==(root/'planet_other_light'/name.name).read_bytes(), name
for face in faces:
    im=Image.open(root/'sky'/f'sky_{face}.png')
    assert im.size==(512,512) and len(im.getcolors(im.width*im.height) or [])>4
assert Image.open(root/'sky/sky_panorama.png').size==(2048,1024)
a=Image.open(root/'planet_light_left.png').convert('RGB')
b=Image.open(root/'godot_reimport.png').convert('RGB')
diff=ImageChops.difference(a,b)
changed=sum(any(c>1 for c in pixel) for pixel in diff.get_flattened_data())
assert changed<a.width*a.height*.005, f'GLB reimport color drift: {changed}'
report={'passed':True,'cube_edges':12,'boundary_samples':len(samples),'max_channel_delta':max_delta,
        'reimport_changed_pixels':changed,'light_independent_textures':True,'models':models}
(root/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
