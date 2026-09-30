extends SceneTree
const Pipeline=preload("res://asset_pipeline.gd")
const Schema=preload("res://parameters.gd")
const Geometry=preload("res://geometry.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var pipe:=Pipeline.new()
	root.add_child(pipe)
	var params:=Schema.defaults("sky")
	params.decor_enabled=true
	params.bright_count=200
	for pixel_art in [false,true]:
		params.pixel_art=pixel_art
		pipe.configure("sky",params)
		pipe.material.set_shader_parameter("edge_test",true)
		pipe.material.set_shader_parameter("resolution",48.0)
		for seconds in [0.0,6.0]:
			pipe.set_noise_time(seconds,params)
			var samples: Dictionary={}
			for face in 6:
				var im: Image=await pipe.bake(face,Vector2i(48,48))
				for y in 48:
					for x in 48:
						if x not in [0,47] and y not in [0,47]: continue
						var direction:=Geometry.cube_point(face,Vector2(x,y)/47.0).snapped(Vector3.ONE*.00001)
						var color:=im.get_pixel(x,y)
						assert(not samples.has(direction) or color.is_equal_approx(samples[direction]),"Sky cube seam, including stars and distant planets")
						samples[direction]=color
	var probe:=Shader.new()
	probe.code='shader_type canvas_item;\nrender_mode unshaded;\n#include "res://noise_core.gdshaderinc"\nvoid fragment(){vec2 uv=(UV*vec2(128,64)-.5)/vec2(127,63);COLOR=evaluate_direction(direction(uv));}'
	pipe.material.shader=probe
	for pixel_art in [false,true]:
		params.pixel_art=pixel_art
		pipe.configure("sky",params)
		for seconds in [0.0,6.0]:
			pipe.set_noise_time(seconds,params)
			var panorama: Image=await pipe.bake(6,Vector2i(128,64))
			for y in 64: assert(panorama.get_pixel(0,y).is_equal_approx(panorama.get_pixel(127,y)),"Panorama left/right seam")
			for x in 128:
				assert(panorama.get_pixel(x,0).is_equal_approx(panorama.get_pixel(0,0)),"North pole must be a single direction")
				assert(panorama.get_pixel(x,63).is_equal_approx(panorama.get_pixel(0,63)),"South pole must be a single direction")
	pipe.queue_free()
	await process_frame
	print("SKY_CONTINUITY_OK: 12 cube edges, panorama seam, poles, animated/smooth/pixel modes with bright stars and distant planets")
	quit()
