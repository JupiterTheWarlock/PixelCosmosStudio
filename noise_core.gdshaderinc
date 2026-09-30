uniform bool noise_enabled=true;
uniform float noise_duration=24.0;
uniform float noise_time=0.0;
uniform bool cloud_motion=true;
uniform float cloud_strength=.35;
uniform int cloud_cycles=1;
uniform bool water_motion=true;
uniform float water_strength=.5;
uniform int water_cycles=2;
uniform bool gas_motion=true;
uniform float gas_strength=.35;
uniform int gas_cycles=1;
uniform bool nebula_motion=true;
uniform float nebula_strength=.22;
uniform int nebula_cycles=1;
// Intrinsic colors only: no illumination is baked. Deep-Fold adaptations.
uniform int face=0;
uniform int kind=0;
uniform int planet_type=2;
uniform float seed=8.421;
uniform float resolution=128.0;
uniform float pixels=128.0;
uniform bool pixel_art=true;
uniform bool dither=true;
uniform float dither_size=1.0;
uniform float rotation=0.0;
uniform bool edge_test=false;
uniform bool clouds_only=false;
uniform float surface_seed=0.0;
uniform float noise_scale=2.146;
uniform int octaves=5;
uniform float land_cutoff=.55;
uniform bool land_enabled=true;
uniform bool water_enabled=true;
uniform bool rivers_enabled=true;
uniform bool lakes_enabled=true;
uniform bool craters_enabled=true;
uniform float river_cutoff=.04;
uniform float lake_cutoff=.38;
uniform float crater_scale=9.0;
uniform float crater_depth=.6;
uniform float ice_coverage=.35;
uniform float lava_cutoff=.55;
uniform float bands=16.0;
uniform float swirl=2.2;
uniform float cloud_seed=13.0;
uniform float cloud_cover=.48;
uniform float cloud_scale=3.8725;
uniform int cloud_octaves=3;
uniform float cloud_stretch=1.0;
uniform float cloud_curve=1.3;
uniform vec4 water0=vec4(.572549,.909804,.752941,1);
uniform vec4 water1=vec4(.309804,.643137,.721569,1);
uniform vec4 water2=vec4(.172549,.207843,.301961,1);
uniform vec4 land0=vec4(.784314,.831373,.364706,1);
uniform vec4 land1=vec4(.388235,.670588,.247059,1);
uniform vec4 land2=vec4(.184314,.341176,.32549,1);
uniform vec4 land3=vec4(.156863,.207843,.25098,1);
uniform vec4 cloud0=vec4(.87451,.878431,.909804,1);
uniform vec4 cloud1=vec4(.639216,.654902,.760784,1);
uniform vec4 cloud2=vec4(.407843,.435294,.6,1);
uniform vec4 cloud3=vec4(.25098,.286275,.45098,1);
uniform vec4 background_color=vec4(.075,.078,.05,1);
uniform bool transparent=false;
uniform bool reduce_background=false;
uniform bool nebula_enabled=true;
uniform float nebula_seed=0.0;
uniform float nebula_scale=5.0;
uniform int nebula_octaves=5;
uniform float density=.5;
uniform float nebula_brightness=1.0;
uniform bool dust_enabled=true;
uniform float dust_seed=2.0;
uniform float dust_scale=10.0;
uniform int dust_octaves=5;
uniform float dust_density=1.8;
uniform float dust_brightness=1.0;
uniform bool stars_enabled=true;
uniform float stars_seed=73.0;
uniform float star_density=.004;
uniform float star_size=1.0;
uniform float star_brightness=1.0;
uniform bool bright_enabled=true;
uniform int bright_count=100;
uniform float bright_size=.07;
uniform bool decor_enabled=false;
uniform int decor_count=8;
uniform float decor_size=.04;
uniform sampler2D star_atlas : filter_nearest, repeat_disable;
uniform vec4 palette0=vec4(.12549,.13333,.08235,1);
uniform vec4 palette1=vec4(.22745,.15686,.00784,1);
uniform vec4 palette2=vec4(.58824,.23529,.23529,1);
uniform vec4 palette3=vec4(.79216,.35294,.18039,1);
uniform vec4 palette4=vec4(1,.47059,.19216,1);
uniform vec4 palette5=vec4(.95294,.6,.28628,1);
uniform vec4 palette6=vec4(.92157,.76078,.45882,1);
uniform vec4 palette7=vec4(.87451,.84314,.52157,1);

vec3 direction(vec2 uv){
 vec2 q=uv*2.0-1.0;
 if(face==0)return normalize(vec3(1,-q.y,-q.x));
 if(face==1)return normalize(vec3(-1,-q.y,q.x));
 if(face==2)return normalize(vec3(q.x,1,q.y));
 if(face==3)return normalize(vec3(q.x,-1,-q.y));
 if(face==4)return normalize(vec3(q.x,-q.y,1));
 if(face==5)return normalize(vec3(-q.x,-q.y,-1));
 float lon=(uv.x-.5)*TAU,lat=uv.y*PI;
 return vec3(sin(lon)*sin(lat),cos(lat),-cos(lon)*sin(lat));
}
float hash3(vec3 p){return fract(sin(dot(p,vec3(12.9898,78.233,37.719)))*(15.5453+seed));}
float noise3(vec3 p){
 vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),
 mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p,int levels){float v=0.0,a=.5;for(int i=0;i<20;i++){if(i>=levels)break;v+=noise3(p)*a;p*=2.0;a*=.5;}return v;}
float circle_noise(vec3 p){
 float h=hash3(floor(p)),center=.25+h*.5;
 // Keep each feature within its cell so temporal motion never jumps at cell borders.
 float radius=min(max(.001,h*.25),min(center,1.0-center)*.75);
 return smoothstep(0.0,radius,length(fract(p)-vec3(center))*.75);
}
float cloud_field(vec3 p,int levels){float c=circle_noise(p*.5+vec3(.7,1,1))+circle_noise(p*.5+vec3(1.7,2,2));return fbm(p+vec3(c),levels);}
// Explicit periodic time; no engine TIME or frame-dependent random state.
// Integer cycles guarantee every layer returns to phase zero at duration.
vec3 motion_warp(vec3 p,float strength,int cycles){
 if(!noise_enabled||strength==0.0)return vec3(0);
 float phase=fract(noise_time/max(noise_duration,.001))*TAU*float(cycles);
 float a=sin(phase),b=cos(phase)-1.0;
 vec3 field=vec3(noise3(p*.55+vec3(19,3,1)),noise3(p*.55+vec3(2,31,7)),noise3(p*.55+vec3(11,5,43)))*2.0-1.0;
 return strength*(field*a+vec3(field.z,field.x,field.y)*b);
}
vec3 palette_at(int k){
 if(k==0)return palette0.rgb;if(k==1)return palette1.rgb;if(k==2)return palette2.rgb;if(k==3)return palette3.rgb;
 if(k==4)return palette4.rgb;if(k==5)return palette5.rgb;if(k==6)return palette6.rgb;return palette7.rgb;
}
vec3 sky_color(float value){float v=clamp(value,0.0,7.0);int k=int(floor(v));return pixel_art?palette_at(k):mix(palette_at(k),palette_at(min(k+1,7)),fract(v));}
vec3 land_color(float n){if(n<.3)return land3.rgb;if(n<.44)return land2.rgb;if(n<.58)return land1.rgb;return land0.rgb;}
vec3 ocean_color(float n){return n<.3?water2.rgb:(n<.48?water1.rgb:water0.rgb);}
vec3 random_direction(float i,float salt){float y=hash3(vec3(i,31,salt))*2.0-1.0,a=hash3(vec3(i,17,salt+3.0))*TAU;return vec3(sqrt(max(0.0,1.0-y*y))*cos(a),y,sqrt(max(0.0,1.0-y*y))*sin(a));}
vec4 evaluate_direction(vec3 d){
 float angle=rotation;
 d=vec3(cos(angle)*d.x-sin(angle)*d.z,d.y,sin(angle)*d.x+cos(angle)*d.z);
 if(pixel_art)d=normalize(floor(d*pixels)+.5);
 float stipple=(pixel_art&&dither)?(mod(dot(floor(d*pixels/dither_size),vec3(1)),2.0)*.04-.02):0.0;
 vec3 col=vec3(0);float alpha=1.0;
 if(kind==1){
  col=background_color.rgb;alpha=transparent?0.0:1.0;
  vec3 p=d*nebula_scale+vec3(nebula_seed*.13);
  if(nebula_motion)p+=motion_warp(p,nebula_strength,nebula_cycles);
  float n=cloud_field(p,nebula_octaves),n2=fbm(p+vec3(1),nebula_octaves);
  float dust_lerp=n*n2*n*(1.0+stipple),threshold=.19+density*.24;
  float a=step(n2,threshold),a2=step(n2,threshold+.015);
  float band=dust_lerp*(a2>a?35.0:14.0)*nebula_brightness;
  if(reduce_background)band*=.65;
  float nd=cloud_field(d*dust_scale+vec3(dust_seed*.13),dust_octaves)*fbm(d*dust_scale*.2-vec3(dust_seed),dust_octaves);
  float da=step(fbm(d*dust_scale*.5+vec3(dust_seed),dust_octaves),nd*dust_density);
  float dc=pow(nd*(1.0+stipple),3.2)*56.0*dust_brightness;
  if(dust_enabled&&da>.5&&(!nebula_enabled||a2<.5)){col=sky_color(dc);alpha=1.0;}
  if(nebula_enabled&&a2>.5&&band>=1.0){col=sky_color(band);alpha=1.0;}
  vec3 cell=floor(d*180.0/star_size);
  if(stars_enabled&&hash3(cell+vec3(stars_seed))>1.0-star_density){col=sky_color((4.0+floor(hash3(cell)*4.0))*star_brightness);alpha=1.0;}
  if(bright_enabled){for(int i=0;i<200;i++){
   if(i>=bright_count)break;float fi=float(i);vec3 sd=random_direction(fi,7.0+stars_seed*.1);
   if(dot(sd,d)>1.0-bright_size*bright_size){
    vec3 axis=abs(sd.y)>.95?vec3(1,0,0):vec3(0,1,0),right=normalize(cross(axis,sd)),up=cross(sd,right);
    vec2 st=vec2(dot(d,right),-dot(d,up))/bright_size+.5;
    if(all(greaterThanEqual(st,vec2(0)))&&all(lessThan(st,vec2(1)))){
     vec4 sprite=texture(star_atlas,vec2((st.x+mod(fi,5.0))/6.0,st.y));
     col=mix(col,sky_color(round(sprite.r*7.0)*star_brightness),sprite.a);alpha=max(alpha,sprite.a);
    }
   }
  }}
  if(decor_enabled){for(int i=0;i<32;i++){
   if(i>=decor_count)break;vec3 sd=random_direction(float(i),123.0);
   float distance_to_planet=length(d-sd);
   // PixelSpace fork Planet.tscn: 0.485..0.505 around a radius of 0.5.
   float coverage=pixel_art?(distance_to_planet<decor_size?1.0:0.0):1.0-smoothstep(.97*decor_size,1.01*decor_size,distance_to_planet);
   if(coverage>0.0){
    vec3 planet_color=sky_color(2.0+fbm(d*90.0,3)*4.0);
    // Straight alpha, including transparent exports and overlapping planets.
    float combined_alpha=coverage+alpha*(1.0-coverage);
    col=(planet_color*coverage+col*alpha*(1.0-coverage))/combined_alpha;
    alpha=combined_alpha;
   }
  }}
 }else{
  vec3 p=d*noise_scale+vec3(2.0+surface_seed*.13);float n=fbm(p,octaves)+stipple;
  col=land_color(n);
  bool water_region=false;
  float water_value=n;
  if(planet_type==0||planet_type==2){
   water_region=!(n>land_cutoff&&land_enabled);
   col=n>land_cutoff&&land_enabled?land_color(fbm(p+vec3(5),octaves)*.5+.4):ocean_color(n);
   if(!water_enabled&&(n<=land_cutoff||!land_enabled))alpha=0.0;
   if(planet_type==0&&((rivers_enabled&&abs(fbm(p*1.5+vec3(9),octaves)-.5)<river_cutoff)||(lakes_enabled&&n<lake_cutoff))){col=ocean_color(.42);water_region=true;water_value=.42;}
  }
  if(planet_type==3||planet_type==7){
   vec3 cp=d*crater_scale;float h=hash3(floor(cp));
   float crater=1.0-smoothstep(h*.1+.12,h*.2+.3,length(fract(cp)-.5));
   if(craters_enabled)col=mix(col,land3.rgb,crater*crater_depth);
   if(planet_type==7&&abs(fbm(p*2.0,octaves)-.5)<(1.0-lava_cutoff)*.2)col=mix(land0.rgb,land1.rgb,n);
  }
  if(planet_type==4||planet_type==5){
   vec3 gp=vec3(d.x*noise_scale,d.y*bands+n*swirl,d.z*noise_scale);
   if(gas_motion)gp+=motion_warp(gp,gas_strength,gas_cycles);
   float gas=fbm(gp,octaves)+stipple;
   if(planet_type==5)gas+=sin(d.y*bands*PI)*.10;
   col=land_color(gas);
  }
  if(planet_type==6){
   float ice=abs(d.y)+n*.3;col=ice>1.0-ice_coverage?land0.rgb:land_color(n+.12);
   if(lakes_enabled&&n<lake_cutoff&&ice<1.0-ice_coverage){col=ocean_color(n);water_region=true;}
  }
  if(water_region&&water_motion&&noise_enabled){
   vec3 wp=p*2.5;
   float change=fbm(wp+motion_warp(wp,water_strength,water_cycles),3)-fbm(wp,3);
   col=ocean_color(water_value+change*.8);
  }
  if(clouds_only){
   vec3 cp=d*cloud_scale+vec3(cloud_seed);cp.y=cp.y*cloud_stretch+sin(cp.x)*cloud_curve;
   if(cloud_motion)cp+=motion_warp(cp,cloud_strength,cloud_cycles);
   float c=cloud_field(cp,cloud_octaves)+stipple;alpha=step(cloud_cover,c);
   col=c<.35?cloud3.rgb:(c<.45?cloud2.rgb:(c<.55?cloud1.rgb:cloud0.rgb));
  }
 }
 return vec4(clamp(col,vec3(0),vec3(1)),alpha);
}
