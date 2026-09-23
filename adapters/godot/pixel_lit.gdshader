shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D base_color : source_color, filter_nearest;
uniform bool textured=true;
uniform bool vertex_colored=false;
uniform bool alpha_clip=false;
uniform float levels=4.0;
uniform float dither_strength=.08;
void fragment(){
 vec4 c=textured?texture(base_color,UV):vec4(1);
 if(vertex_colored)c*=COLOR;
 if(alpha_clip&&c.a<.5)discard;
 ALBEDO=c.rgb;ROUGHNESS=1.0;SPECULAR=0.0;
}
void light(){
 float pattern=mod(floor(FRAGCOORD.x)+floor(FRAGCOORD.y),2.0)-.5;
 float l=clamp(dot(NORMAL,LIGHT)+pattern*dither_strength,0.0,1.0);
 l=floor(l*(levels-1.0)+.5)/max(1.0,levels-1.0);
 DIFFUSE_LIGHT+=LIGHT_COLOR*l*ATTENUATION/PI;
}
