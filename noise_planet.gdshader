shader_type spatial;
render_mode cull_disabled;
#include "res://noise_core.gdshaderinc"
uniform float material_roughness=1.0;
uniform float material_metallic=0.0;
uniform bool linear_output=false;
uniform bool voxel_surface=false;
uniform float voxel_density=32.0;
varying vec3 local_normal;
varying vec3 local_position;
void vertex(){local_position=VERTEX;local_normal=NORMAL;}
void fragment(){
 vec3 sample_position=local_position;
 if(voxel_surface){
  float cell_size=2.0/voxel_density;
  // Move into the occupied cell before quantizing a boundary face.
  vec3 cell=floor((local_position-local_normal*cell_size*.001+vec3(1.0))/cell_size);
  sample_position=(cell+vec3(.5))*cell_size-vec3(1.0);
 }
 vec4 c=evaluate_direction(normalize(sample_position));
 if(c.a<.5)discard;
 // The generator outputs sRGB palette values; spatial ALBEDO is linear.
 ALBEDO=linear_output?mix(c.rgb/12.92,pow((c.rgb+.055)/1.055,vec3(2.4)),step(vec3(.04045),c.rgb)):c.rgb;
 ROUGHNESS=material_roughness;METALLIC=material_metallic;
}
