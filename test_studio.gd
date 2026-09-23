extends RefCounted

const Pipeline = preload("res://asset_pipeline.gd")
const Schema = preload("res://parameters.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func capture(viewport: Viewport, path: String) -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	image.save_png(path)
	return image

func run(studio: Control) -> void:
	var root: String = ProjectSettings.globalize_path("res://exports/v2")
	DirAccess.make_dir_recursive_absolute(root)
	var p: Dictionary = studio.pages.planet
	var s: Dictionary = studio.pages.sky
	var initial_sky: PackedByteArray = s.result.images[0].get_data()
	var initial_base: PackedByteArray = p.result.images[0].get_data()
	var light_a: Image = await capture(p.viewport,root.path_join("planet_light_left.png"))
	await capture(studio.get_viewport(),root.path_join("planet_tab.png"))
	check(Pipeline.export_assets(p.result,root.path_join("planet"))==OK,"Planet export")
	p.light_azimuth = 100.0
	studio.update_lighting()
	var light_b: Image = await capture(p.viewport,root.path_join("planet_light_right.png"))
	check(light_a.get_data()!=light_b.get_data(),"Moving light must change rendered image")
	check(initial_base==p.result.images[0].get_data(),"Light must not change base-color assets")
	var base_unchanged: bool = initial_base==p.result.images[0].get_data()
	check(Pipeline.export_assets(p.result,root.path_join("planet_other_light"))==OK,"Second light export")
	p.energy = 0
	p.ambient = 0
	studio.update_lighting()
	var dark: Image = await capture(p.viewport,root.path_join("lights_off.png"))
	var middle: Color = dark.get_pixel(dark.get_width()/2,dark.get_height()/2)
	check(middle.r<.02&&middle.g<.02&&middle.b<.02,"Lights off: center must be dark")
	p.energy = 1.0
	p.ambient = .65
	p.light_azimuth = -35.0
	studio.update_lighting()
	p.style = true
	studio.apply_style()
	await capture(p.viewport,root.path_join("pixel_lighting.png"))
	p.light_azimuth = 100.0
	studio.update_lighting()
	await capture(p.viewport,root.path_join("pixel_lighting_right.png"))
	p.style = false
	p.light_azimuth = -35.0
	studio.apply_style()
	studio.update_lighting()
	# Import/export roundtrip renders in the same lights. No runtime generation dependency.
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	check(doc.append_from_file(root.path_join("planet/planet.glb"),state)==OK,"GLB import")
	var imported: Node = doc.generate_scene(state)
	p.result.node.visible = false
	p.world.add_child(imported)
	await capture(p.viewport,root.path_join("godot_reimport.png"))
	imported.free()
	p.result.node.visible = true
	# Preset roundtrip is exact, invalid presets cannot change state.
	var original: Dictionary = p.parameters.duplicate(true)
	var preset: String = root.path_join("roundtrip.json")
	Pipeline.write_json(preset,{"format":"pixel-cosmos-preset","version":2,"domain":"planet","parameters":original})
	p.parameters.seed = 42
	check(studio.load_preset("planet",preset).is_empty(),"Load preset")
	check(p.parameters==original,"Preset restores every parameter")
	var invalid: Dictionary = original.duplicate(true)
	invalid.face_size = 999999
	Pipeline.write_json(root.path_join("invalid.json"),{"format":"pixel-cosmos-preset","version":2,"domain":"planet","parameters":invalid})
	check(not studio.load_preset("planet",root.path_join("invalid.json")).is_empty(),"Reject out-of-bounds preset")
	check(p.parameters==original,"Invalid preset leaves state unchanged")
	var type_hashes: Array[int] = []
	for index in 8:
		p.parameters = Schema.type_defaults(index)
		p.parameters.face_size = 64
		studio._sync_widgets("planet")
		await studio.generate("planet")
		type_hashes.append(hash(p.result.images[0].get_data()))
		await capture(p.viewport,root.path_join("type_%d.png"%index))
		check(Pipeline.export_assets(p.result,root.path_join("type_%d"%index))==OK,"Export type "+str(index))
	check(initial_sky==s.result.images[0].get_data(),"Planet regeneration leaves sky unchanged")
	var unique: Dictionary = {}
	for value in type_hashes: unique[value] = true
	check(unique.size()==8,"Eight types must have distinct surfaces")
	p.parameters = Schema.defaults("planet")
	p.parameters.voxel = true
	await studio.generate("planet")
	await capture(p.viewport,root.path_join("voxel.png"))
	check(Pipeline.export_assets(p.result,root.path_join("voxel"))==OK,"Voxel export")
	# Deterministic generation and sky/planet independence.
	await studio.generate("sky")
	check(initial_sky==s.result.images[0].get_data(),"Sky determinism")
	check(Pipeline.export_assets(s.result,root.path_join("sky"))==OK,"Sky export")
	studio.tabs.current_tab = 1
	await capture(s.viewport,root.path_join("sky.png"))
	await capture(studio.get_viewport(),root.path_join("sky_tab.png"))
	# Inspect the real sky across upper/lower cube boundaries and both poles.
	for angles in [Vector2(45,0),Vector2(90,0),Vector2(-90,0),Vector2(45,90),Vector2(-45,180)]:
		s.camera.rotation = Vector3(deg_to_rad(angles.x),deg_to_rad(angles.y),0)
		await capture(s.viewport,root.path_join("sky_view_%d_%d.png"%[angles.x,angles.y]))
	s.camera.rotation = Vector3.ZERO
	# Exact shared-direction edge samples; not adjacent texel-center comparisons.
	s.pipeline.configure("sky",s.parameters)
	s.pipeline.material.set_shader_parameter("edge_test",true)
	s.pipeline.material.set_shader_parameter("resolution",64.0)
	for face in 6:
		var edge: Image = await s.pipeline.bake(face,Vector2i(64,64))
		edge.save_png(root.path_join("edge_"+Pipeline.FACES[face]+".png"))
	# Layer switches and transparent export really affect output.
	var empty: Dictionary = s.parameters.duplicate(true)
	for key in ["nebula_enabled","dust_enabled","stars_enabled","bright_enabled","decor_enabled"]: empty[key]=false
	empty.transparent = true
	empty.face_size = 32
	s.pipeline.configure("sky",empty)
	var transparent_image: Image = await s.pipeline.bake(0,Vector2i(32,32))
	check(transparent_image.is_invisible(),"Disabled sky layers produce transparent image")
	var report: Dictionary = {"failures":failures,"passed":failures.is_empty(),"planet_parameter_count":Schema.fields("planet").size(),"sky_parameter_count":Schema.fields("sky").size(),"distinct_planet_types":unique.size(),"lighting_changes_preview":light_a.get_data()!=light_b.get_data(),"base_color_unchanged_by_light":base_unchanged}
	Pipeline.write_json(root.path_join("godot_report.json"),report)
	print("V2_TEST_RESULT "+JSON.stringify(report))
	studio.get_tree().quit(0 if failures.is_empty() else 1)
