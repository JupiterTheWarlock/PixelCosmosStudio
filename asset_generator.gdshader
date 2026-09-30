shader_type canvas_item;
// Write straight RGBA to the export viewport; blending would premultiply soft edges.
render_mode unshaded, blend_disabled;
#include "res://noise_core.gdshaderinc"
void fragment(){
 vec2 uv=UV;
 if(edge_test)uv=(UV*resolution-.5)/(resolution-1.0);
 COLOR=evaluate_direction(direction(uv));
}
