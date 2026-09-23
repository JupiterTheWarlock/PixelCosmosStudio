shader_type sky;
#include "res://noise_core.gdshaderinc"
uniform bool linear_output=false;
void sky(){
 vec3 c=evaluate_direction(EYEDIR).rgb;
 COLOR=linear_output?mix(c/12.92,pow((c+.055)/1.055,vec3(2.4)),step(vec3(.04045),c)):c;
}
