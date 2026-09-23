import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';

/** All models remain ordinary three.js meshes and replaceable materials. */
export async function loadPlanet(url, manifestUrl) {
  const gltf = await new GLTFLoader().loadAsync(url);
  const manifest = manifestUrl ? await fetch(manifestUrl).then(r => {
    if (!r.ok) throw new Error(`Manifest HTTP ${r.status}`);
    return r.json();
  }) : null;
  if (manifest && (manifest.version !== 2 || manifest.domain !== 'planet'))
    throw new Error('Expected a Pixel Cosmos v2 planet manifest');
  const root = gltf.scene;
  root.traverse(node => {
    if (!node.isMesh) return;
    for (const material of [].concat(node.material)) {
      if (material.map && manifest) {
        material.map.magFilter = THREE.NearestFilter;
        material.map.minFilter = THREE.NearestFilter;
        if (!manifest.parameters.pixel_art) {
          material.map.magFilter = THREE.LinearFilter;
          material.map.minFilter = THREE.LinearFilter;
        }
        material.map.generateMipmaps = false;
        material.map.needsUpdate = true;
      }
    }
  });
  return {
    root, manifest,
    update(seconds) {
      if (!manifest) return;
      const p = manifest.parameters;
      root.rotation.y += THREE.MathUtils.degToRad(p.rotation_speed) * seconds;
      const clouds = root.getObjectByName('CloudShell');
      if (clouds) clouds.rotation.y += THREE.MathUtils.degToRad(p.cloud_speed) * seconds;
    },
    dispose() {
      const textures = new Set(), materials = new Set(), meshes = new Set();
      root.traverse(node => {
        if (!node.isMesh) return;
        meshes.add(node.geometry);
        for (const mat of [].concat(node.material)) {
          materials.add(mat);
          for (const v of Object.values(mat)) if (v?.isTexture) textures.add(v);
        }
      });
      textures.forEach(t => {t.source?.data?.close?.();t.dispose();});
      materials.forEach(m => m.dispose()); meshes.forEach(g => g.dispose());
      root.removeFromParent();
    }
  };
}

/** Optional toon material. No fullscreen postprocess or renderer replacement. */
export function usePixelLighting(root, levels = 4) {
  const count = Math.max(2, Math.min(8, Math.round(levels)));
  const data = new Uint8Array(count);
  for(let i=0;i<count;i++) data[i]=Math.round(i*255/(count-1));
  const ramp = new THREE.DataTexture(data,count,1,THREE.RedFormat);
  ramp.minFilter=THREE.NearestFilter; ramp.magFilter=THREE.NearestFilter;
  ramp.needsUpdate=true;
  const originals=[];
  root.traverse(node => {
    if(!node.isMesh) return;
    originals.push([node,node.material]);
    const convert=m => new THREE.MeshToonMaterial({map:m.map,color:m.color,vertexColors:m.vertexColors,
      alphaTest:m.alphaTest,transparent:m.transparent,opacity:m.opacity,side:m.side,
      gradientMap:ramp});
    node.material=Array.isArray(node.material)?node.material.map(convert):convert(node.material);
  });
  return () => {
    originals.forEach(([node,old])=>{[].concat(node.material).forEach(m=>m.dispose());node.material=old;});
    ramp.dispose();
  };
}

/** PNG faces are ordered +X,-X,+Y,-Y,+Z,-Z. */
export async function loadSky(folder) {
  const base=folder.endsWith('/')?folder:folder+'/';
  const cube = await new THREE.CubeTextureLoader().loadAsync(
    ['px','nx','py','ny','pz','nz'].map(face=>`${base}sky_${face}.png`));
  cube.colorSpace=THREE.SRGBColorSpace;
  cube.magFilter=THREE.NearestFilter; cube.minFilter=THREE.NearestFilter;
  cube.generateMipmaps=false;
  return cube; // assign scene.background; environment lighting is explicitly opt-in.
}
