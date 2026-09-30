shader_type sky;
#include "res://noise_core.gdshaderinc"
uniform bool linear_output=false;
void sky(){
 vec4 sample_color=evaluate_direction(EYEDIR);
 // A sky has no alpha channel. Preview transparent layers on the chosen background.
 vec3 c=mix(background_color.rgb,sample_color.rgb,sample_color.a);
 COLOR=linear_output?mix(c/12.92,pow((c+.055)/1.055,vec3(2.4)),step(vec3(.04045),c)):c;
}
