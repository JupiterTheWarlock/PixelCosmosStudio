shader_type canvas_item;
render_mode unshaded;
#include "res://noise_core.gdshaderinc"
void fragment(){
 vec2 uv=UV;
 if(edge_test)uv=(UV*resolution-.5)/(resolution-1.0);
 COLOR=evaluate_direction(direction(uv));
}
