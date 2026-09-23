extends RefCounted

const Schema=preload("res://parameters.gd")
const Motion=preload("res://noise_motion.gd")
const Pipeline=preload("res://asset_pipeline.gd")
var failures: Array[String]=[]

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func capture(view: Viewport, path: String) -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var im: Image=view.get_texture().get_image()
	im.save_png(path)
	return im

func run(studio: Control) -> void:
	var folder: String="res://exports/motion"
	DirAccess.make_dir_recursive_absolute(folder)
	var pipe := Pipeline.new()
	studio.add_child(pipe)
	var hashes: Dictionary={}
	for layer in ["cloud","water","gas","nebula"]:
		var domain: String="sky" if layer=="nebula" else "planet"
		var p: Dictionary=Schema.type_defaults(5) if layer=="gas" else Schema.defaults(domain)
		p.face_size=64
		if layer=="water": p.land_cutoff=.5
		pipe.configure(domain,p)
		pipe.set_noise_time(0,p)
		var first: Image=await pipe.bake(0,Vector2i(64,64),layer=="cloud")
		pipe.set_noise_time(p.noise_duration*.25,p)
		var second: Image=await pipe.bake(0,Vector2i(64,64),layer=="cloud")
		pipe.set_noise_time(p.noise_duration,p)
		var looped: Image=await pipe.bake(0,Vector2i(64,64),layer=="cloud")
		check(first.get_data()!=second.get_data(),layer+" must evolve")
		check(first.get_data()==looped.get_data(),layer+" must loop exactly")
		first.save_png(folder.path_join(layer+"_0.png"))
		second.save_png(folder.path_join(layer+"_quarter.png"))
		if layer=="water":
			var count: int=0
			for y in 64:
				for x in 64:
					var c: String=first.get_pixel(x,y).to_html(false)
					if c in [p.land0,p.land1,p.land2,p.land3]:
						count+=1
						check(first.get_pixel(x,y)==second.get_pixel(x,y),"Land changed during water motion")
			check(count>0,"Water test must contain land")
		hashes[layer]=[hash(first.get_data()),hash(second.get_data())]
		p[layer+"_strength"]=0.0
		pipe.configure(domain,p)
		pipe.set_noise_time(6,p)
		var zero: Image=await pipe.bake(0,Vector2i(64,64),layer=="cloud")
		check(zero.get_data()==first.get_data(),layer+" zero strength must freeze")
	var stars: Dictionary=Schema.defaults("sky")
	stars.nebula_enabled=false
	stars.dust_enabled=false
	pipe.configure("sky",stars)
	var stars0: Image=await pipe.bake(0,Vector2i(64,64))
	pipe.set_noise_time(6,stars)
	var stars1: Image=await pipe.bake(0,Vector2i(64,64))
	check(stars0.get_data()==stars1.get_data(),"Stars must stay fixed")
	# Compare common spherical directions across all six faces at a moving phase.
	var edge_params: Dictionary=Schema.defaults("sky")
	pipe.configure("sky",edge_params)
	pipe.set_noise_time(6,edge_params)
	pipe.material.set_shader_parameter("edge_test",true)
	pipe.material.set_shader_parameter("resolution",32.0)
	var edges: Dictionary={}
	for face in 6:
		var edge: Image=await pipe.bake(face,Vector2i(32,32))
		for y in 32:
			for x in 32:
				if x not in [0,31] and y not in [0,31]: continue
				var d: Vector3=preload("res://geometry.gd").cube_point(face,Vector2(x,y)/31.0).snapped(Vector3.ONE*.00001)
				var c: Color=edge.get_pixel(x,y)
				if edges.has(d): check(c.is_equal_approx(edges[d]),"Animated cube edge mismatch")
				else: edges[d]=c
	# Real GPU preview uses the same kernel, with an explicit frozen timeline.
	for domain in ["planet","sky"]:
		var d: Dictionary=studio.pages[domain]
		d.motion_preview=true
		studio._apply_motion(domain)
		studio.tabs.current_tab=0 if domain=="planet" else 1
		d.settings_tabs.current_tab=1
		studio._set_motion_time(domain,0)
		var a: Image=await capture(d.viewport,folder.path_join(domain+"_preview_0.png"))
		studio._set_motion_time(domain,6)
		var b: Image=await capture(d.viewport,folder.path_join(domain+"_preview_6.png"))
		check(a.get_data()!=b.get_data(),domain+" live shader did not animate")
		await capture(studio.get_viewport(),folder.path_join(domain+"_ui.png"))
	studio.pages.planet.style=true
	studio.apply_style()
	await capture(studio.pages.planet.viewport,folder.path_join("planet_toon.png"))
	studio.pages.planet.parameters=Schema.type_defaults(5)
	await studio.generate("planet")
	studio._set_motion_time("planet",6)
	await capture(studio.pages.planet.viewport,folder.path_join("gas_preview.png"))
	studio.pages.planet.parameters.voxel=true
	await studio.generate("planet")
	await capture(studio.pages.planet.viewport,folder.path_join("voxel_preview.png"))
	# A small real animation export exercises the same time/parameter contract.
	var exported: Dictionary=Schema.defaults("sky")
	exported.face_size=32
	exported.noise_frames=8
	check(await pipe.export_animation("sky",exported,folder.path_join("animation"))==OK,"Animation export")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("animation/animation.json")))
	check(manifest.complete and manifest.completed_frames==8,"Export completeness")
	for key in exported:
		var actual: Variant=manifest.parameters[key]
		var expected: Variant=exported[key]
		check(is_equal_approx(float(actual),float(expected)) if expected is float or expected is int else actual==expected,"Export parameter mismatch: "+key)
	var context: String=Motion.context("sky",exported)
	check(context.contains(Motion.VERSION) and context.contains(manifest.source_sha256),"Context must use same version/hash")
	var cancel_state: Dictionary={"cancel":false}
	var cancel_error: Error=await pipe.export_animation("sky",exported,folder.path_join("cancelled"),func(_frame: int,_total: int) -> void: cancel_state.cancel=true,func() -> bool: return cancel_state.cancel)
	check(cancel_error==ERR_SKIP,"Cancel should stop export")
	var partial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("cancelled/animation.json")))
	check(not partial.complete and partial.completed_frames==1,"Partial export must be marked incomplete")
	Pipeline.write_json(folder.path_join("report.json"),{"passed":failures.is_empty(),"failures":failures,"layers":hashes,"animation_frames":8,"stationary_stars":true})
	print("MOTION_TEST_RESULT "+JSON.stringify(failures))
	studio.get_tree().quit(0 if failures.is_empty() else 1)
