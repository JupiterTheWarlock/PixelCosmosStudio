extends SceneTree

const Pipeline=preload("res://asset_pipeline.gd")
const Schema=preload("res://parameters.gd")
const OUTPUT="res://exports/smooth"
var failures: Array[String]=[]

func _initialize() -> void: call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func color_count(image: Image) -> int:
	var colors: Dictionary={}
	for y in image.get_height():
		for x in image.get_width(): colors[image.get_pixel(x,y).to_rgba32()]=true
	return colors.size()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var pipe:=Pipeline.new()
	root.add_child(pipe)
	var params:=Schema.defaults("sky")
	params.stars_enabled=false
	params.bright_enabled=false
	params.decor_enabled=false
	params.pixels=100
	var counts: Dictionary={}
	# Smooth mode generates intermediate colors, without blurring a quantized image.
	for layer in ["nebula","dust"]:
		params.nebula_enabled=layer=="nebula"
		params.dust_enabled=layer=="dust"
		params.pixel_art=false
		params.dither=true
		params.pixels=100
		pipe.configure("sky",params)
		var smooth: Image=await pipe.bake(6,Vector2i(512,256))
		smooth.save_png(OUTPUT.path_join(layer+"_smooth.png"))
		params.pixels=3000
		params.dither=false
		params.dither_size=8
		pipe.configure("sky",params)
		var unchanged: Image=await pipe.bake(6,Vector2i(512,256))
		check(smooth.get_data()==unchanged.get_data(),layer+": smooth mode must ignore pixel density and dithering")
		params.pixel_art=true
		params.pixels=100
		pipe.configure("sky",params)
		var pixel: Image=await pipe.bake(6,Vector2i(512,256))
		pixel.save_png(OUTPUT.path_join(layer+"_pixel.png"))
		var smooth_colors:=color_count(smooth)
		var pixel_colors:=color_count(pixel)
		counts[layer]={"smooth":smooth_colors,"pixel":pixel_colors}
		check(smooth_colors>16,layer+": smooth colors must extend beyond the eight-color palette")
		check(pixel_colors>1 and pixel_colors<=9,layer+": pixel colors must remain within palette + background")
		check(smooth.get_data()!=pixel.get_data(),layer+": render modes must look different")
		params.pixels=3000
		pipe.configure("sky",params)
		var denser: Image=await pipe.bake(6,Vector2i(512,256))
		check(pixel.get_data()!=denser.get_data(),layer+": density must still affect pixel mode")
		if layer=="nebula":
			params.pixel_art=false
			pipe.configure("sky",params)
			pipe.set_noise_time(params.noise_duration*.25,params)
			var moving: Image=await pipe.bake(6,Vector2i(512,256))
			check(moving.get_data()!=smooth.get_data(),"Smooth nebula must still animate")
			pipe.set_noise_time(params.noise_duration,params)
			var looped: Image=await pipe.bake(6,Vector2i(512,256))
			check(looped.get_data()==smooth.get_data(),"Smooth animation must loop exactly")
	# Compare transparent output against an opaque render. Dark fringes expose
	# accidental premultiplication while baking the soft silhouette.
	params.nebula_enabled=false
	params.dust_enabled=false
	params.decor_enabled=true
	params.decor_count=32
	params.decor_size=.12
	params.pixel_art=false
	params.background_color="000000"
	params.transparent=true
	pipe.configure("sky",params)
	var transparent: Image=await pipe.bake(6,Vector2i(512,256))
	transparent.save_png(OUTPUT.path_join("planets_smooth_rgba.png"))
	params.transparent=false
	pipe.configure("sky",params)
	var opaque: Image=await pipe.bake(6,Vector2i(512,256))
	var partial_pixels:=0
	var composite_error:=0.0
	for y in transparent.get_height():
		for x in transparent.get_width():
			var rgba:=transparent.get_pixel(x,y)
			if rgba.a<=0.0 or rgba.a>=1.0: continue
			partial_pixels+=1
			var rgb:=opaque.get_pixel(x,y)
			composite_error=maxf(composite_error,maxf(absf(rgba.r*rgba.a-rgb.r),maxf(absf(rgba.g*rgba.a-rgb.g),absf(rgba.b*rgba.a-rgb.b))))
	check(partial_pixels>10,"Distant planets must have partially transparent smooth edges")
	check(composite_error<.012,"PNG must use straight alpha without dark fringes")
	params.pixel_art=true
	params.transparent=true
	pipe.configure("sky",params)
	var pixel_planets: Image=await pipe.bake(6,Vector2i(512,256))
	var partial_pixel_edges:=0
	for y in pixel_planets.get_height():
		for x in pixel_planets.get_width():
			var alpha:=pixel_planets.get_pixel(x,y).a
			if alpha>0.0 and alpha<1.0: partial_pixel_edges+=1
	check(partial_pixel_edges==0,"Pixel mode must retain its hard silhouettes")
	# Render the actual saved Godot sky, not just the generated PNG bytes.
	var faces: Array[Image]=[]
	var rgba_face:=Image.create(8,8,false,Image.FORMAT_RGBA8)
	rgba_face.fill(Color(.8,.4,.2,.5))
	for face in 6: faces.append(rgba_face)
	var background:=Color(.2,.1,.3)
	var view:=SubViewport.new()
	view.size=Vector2i(64,64)
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_SKY
	var sky:=Pipeline.make_sky(faces,false,background)
	check(ResourceSaver.save(sky,OUTPUT.path_join("rgba_sky.res"))==OK,"Save transparent sky resource")
	environment.environment.sky=load(OUTPUT.path_join("rgba_sky.res"))
	view.add_child(environment)
	view.add_child(Camera3D.new())
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var rendered:=view.get_texture().get_image().get_pixel(32,32)
	var stored:=rgba_face.get_pixel(0,0)
	var expected:=background.lerp(stored,stored.a)
	check(absf(rendered.r-expected.r)<.012 and absf(rendered.g-expected.g)<.012 and absf(rendered.b-expected.b)<.012,"Saved sky must composite soft alpha on the selected background")
	# The transparency export option must not change the live sky appearance.
	params.pixel_art=false
	params.background_color="132538"
	params.transparent=true
	environment.environment.sky=Sky.new()
	environment.environment.sky.sky_material=preload("res://noise_motion.gd").sky_material(params)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var live_transparent:=view.get_texture().get_image()
	params.transparent=false
	environment.environment.sky.sky_material=preload("res://noise_motion.gd").sky_material(params)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var live_opaque:=view.get_texture().get_image()
	var live_error:=0.0
	for y in 64:
		for x in 64:
			var a:=live_transparent.get_pixel(x,y)
			var b:=live_opaque.get_pixel(x,y)
			live_error=maxf(live_error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	check(color_count(live_transparent)>1,"Live comparison must contain distant planets")
	check(live_error<.012,"Transparent export setting must preserve the live sky's soft edges")
	Pipeline.write_json(OUTPUT.path_join("report.json"),{"passed":failures.is_empty(),"color_counts":counts,"soft_edge_pixels":partial_pixels,"composite_error":composite_error,"failures":failures})
	view.queue_free()
	pipe.queue_free()
	await process_frame
	print("SKY_SMOOTH_OK" if failures.is_empty() else "SKY_SMOOTH_FAILED")
	quit(0 if failures.is_empty() else 1)
