import * as THREE from 'three';
import {loadPlanet,usePixelLighting,loadSky} from './cosmos.js';
const params=new URLSearchParams(location.search);
const renderer=new THREE.WebGLRenderer({antialias:false,preserveDrawingBuffer:true});
renderer.setSize(560,420); renderer.setPixelRatio(1);
renderer.outputColorSpace=THREE.SRGBColorSpace;
renderer.toneMapping=THREE.NoToneMapping;
document.body.append(renderer.domElement);
const scene=new THREE.Scene();scene.background=new THREE.Color('#121925');
const camera=new THREE.PerspectiveCamera(52,560/420,.05,100);camera.position.z=3.5;
const ambient=new THREE.AmbientLight('white',1.4);scene.add(ambient);
const light=new THREE.DirectionalLight('white',2.0);scene.add(light);
let asset, restore=null, frame=0;
function moveLight(deg){const a=deg*Math.PI/180;light.position.set(Math.sin(a)*3,2,Math.cos(a)*3);}
moveLight(-35);
async function open(url, manifest){
  if(restore){restore();restore=null;} asset?.dispose();
  asset=await loadPlanet(url,manifest);scene.add(asset.root);
  const r=asset.manifest?.parameters.radius||1;camera.position.set(0,0,3.5*r);
  document.querySelector('#status').textContent='模型已加载 · 使用 three.js 的实时灯光';
  window.cosmos={asset,renderer,scene,camera,light,ambient,moveLight,render:()=>renderer.render(scene,camera)};
  window.cosmosReady=true;
}
document.querySelector('#light').addEventListener('input',e=>moveLight(+e.target.value));
document.querySelector('#toon').addEventListener('change',e=>{
  if(restore){restore();restore=null;}
  if(e.target.checked)restore=usePixelLighting(asset.root,4);
});
document.querySelector('#file').addEventListener('change',async e=>{
  const file=e.target.files[0];if(!file)return;
  const url=URL.createObjectURL(file);
  try{await open(url,null);}catch(error){document.querySelector('#status').textContent=error.message;}
  finally{URL.revokeObjectURL(url);}
});
let previous=performance.now();
renderer.setAnimationLoop(now=>{
  const dt=Math.min((now-previous)/1000,.1);previous=now;
  if(asset&&document.querySelector('#animate').checked)asset.update(dt);
  renderer.render(scene,camera);frame++;
});
try{
  await open(params.get('model')||'../../exports/v2/planet/planet.glb',params.get('manifest')||'../../exports/v2/planet/manifest.json');
  if(params.get('sky'))scene.background=await loadSky(params.get('sky'));
}catch(error){window.cosmosError=error.stack;document.querySelector('#status').textContent=error.message;}
