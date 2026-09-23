shader_type spatial;
render_mode cull_disabled;
#include "res://noise_core.gdshaderinc"
uniform float material_roughness=1.0;
uniform float material_metallic=0.0;
uniform bool linear_output=false;
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 vec4 c=evaluate_direction(normalize(local_position));
 if(c.a<.5)discard;
 // The generator outputs sRGB palette values; spatial ALBEDO is linear.
 ALBEDO=linear_output?mix(c.rgb/12.92,pow((c.rgb+.055)/1.055,vec3(2.4)),step(vec3(.04045),c.rgb)):c.rgb;
 ROUGHNESS=material_roughness;METALLIC=material_metallic;
}
