extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var images: Array[Image] = []
	for face in 6:
		var im := Image.create(128,128,false,Image.FORMAT_RGBA8)
		for y in 128:
			for x in 128:
				var d: Vector3 = preload("res://geometry.gd").cube_point(face,Vector2(x+.5,y+.5)/128.0).normalized()
				im.set_pixel(x,y,Color(d.x*.5+.5,d.y*.5+.5,d.z*.5+.5,1))
		images.append(im)
	var cube: Cubemap = preload("res://asset_pipeline.gd").make_cubemap(images)
	var view := SubViewport.new()
	view.size = Vector2i(512,256)
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var rect := ColorRect.new()
	rect.size = Vector2(512,256)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;render_mode unshaded;uniform samplerCube cube:filter_nearest;void fragment(){float lon=(UV.x-.5)*TAU;float lat=UV.y*PI;vec3 d=vec3(sin(lon)*sin(lat),cos(lat),-cos(lon)*sin(lat));COLOR=vec4(abs(texture(cube,d).rgb-(d*.5+.5))*4.0,1);}"
	mat.shader = shader
	mat.set_shader_parameter("cube",cube)
	rect.material = mat
	view.add_child(rect)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var output: Image = view.get_texture().get_image()
	output.save_png("res://exports/v2/sky_mapping_error.png")
	var total: float = 0
	for y in output.get_height():
		for x in output.get_width():
			var c: Color = output.get_pixel(x,y)
			total += maxf(c.r,maxf(c.g,c.b))
	print("CUBE_MAPPING_MEAN_ERROR ",total/(512*256*4))
	var passed: bool = total/(512*256*4)<.01
	rect.queue_free()
	await process_frame
	view.disable_3d = false
	view.own_world_3d = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = preload("res://asset_pipeline.gd").make_sky(images)
	# Verify the saved resource too, rather than only its in-memory preview.
	ResourceSaver.save(environment.environment.sky,"res://exports/v2/sky_direction_probe.res")
	environment.environment.sky = load("res://exports/v2/sky_direction_probe.res")
	view.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 90
	view.add_child(camera)
	var worst: float = 0
	for angles in [Vector2(0,0),Vector2(45,45),Vector2(90,0),Vector2(-90,0),Vector2(45,135),Vector2(-45,-135)]:
		camera.rotation = Vector3(deg_to_rad(angles.x),deg_to_rad(angles.y),0)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: Image = view.get_texture().get_image()
		var error: float = 0
		var count: int = 0
		for y in range(4,256,8):
			for x in range(4,512,8):
				var d: Vector3 = camera.project_ray_normal(Vector2(x+.5,y+.5))
				var c: Color = shot.get_pixel(x,y)
				error += maxf(absf(c.r-(d.x*.5+.5)),maxf(absf(c.g-(d.y*.5+.5)),absf(c.b-(d.z*.5+.5))))
				count += 1
		worst = maxf(worst,error/count)
	print("ACTUAL_SKY_WORST_VIEW_MEAN_ERROR ",worst)
	passed = passed and worst<.02
	preload("res://asset_pipeline.gd").write_json("res://exports/v2/sky_mapping_report.json",{"passed":passed,"cube_mean_error":total/(512*256*4),"actual_sky_worst_view_mean_error":worst,"views":6,"saved_sky_tested":true})
	quit(0 if passed else 1)
