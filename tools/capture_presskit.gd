extends SceneTree

const OUTPUT="res://dist/presskit"
const ThemeSource=preload("res://ui/source_theme.gd")

func _initialize() -> void: call_deferred("run")

func capture(view: Viewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(OUTPUT.path_join(name))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size=Vector2i(1200,760)
	var studio: Control=load("res://main.tscn").instantiate()
	studio.preset_store.path="user://presskit_"+str(Time.get_ticks_usec())+".json"
	root.add_child(studio)
	for i in 600:
		await process_frame
		if studio.pages.has("sky") and not studio.pages.sky.result.is_empty(): break
	assert(not studio.pages.sky.result.is_empty())
	TranslationServer.set_locale("en")
	studio._refresh_tab_titles()
	studio.pages.planet.animate=false
	for domain in ["planet","sky"]:
		studio.pages[domain].motion_playing=false
		studio._set_motion_time(domain,0)
	await capture(root,"01-planets.png")
	var planet: Dictionary=studio.pages.planet.parameters
	planet.voxel=true
	planet.pixels=24
	planet.rings_enabled=true
	await studio.generate("planet")
	studio._sync_widgets("planet")
	await capture(root,"02-voxels.png")
	studio.tabs.current_tab=1
	await capture(root,"03-space.png")
	studio.pages.sky.parameters.pixel_art=false
	studio.pages.sky.parameters.decor_enabled=true
	await studio.generate("sky")
	studio._sync_widgets("sky")
	await capture(root,"04-smooth-space.png")
	# The cover uses the actual generated geometry and sky, not an illustration.
	var cover:=SubViewport.new()
	cover.size=Vector2i(630,500)
	cover.own_world_3d=true
	cover.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(cover)
	var model: Node3D=studio.pages.planet.result.node.duplicate()
	model.rotation=Vector3(0,.5,0)
	cover.add_child(model)
	var environment:=WorldEnvironment.new()
	environment.environment=studio.pages.planet.environment.environment.duplicate(true)
	cover.add_child(environment)
	var light:=OmniLight3D.new()
	light.position=Vector3(-3,3,4)
	light.omni_range=15
	light.light_energy=1.2
	cover.add_child(light)
	var camera:=Camera3D.new()
	cover.add_child(camera)
	camera.position=Vector3(1,1.4,4.5)
	camera.look_at(Vector3(0,.25,0))
	camera.fov=48
	var overlay:=Control.new()
	overlay.theme=ThemeSource.build()
	cover.add_child(overlay)
	var top:=ColorRect.new()
	top.color=Color("08141ee8")
	top.size=Vector2(630,114)
	overlay.add_child(top)
	var title:=Label.new()
	title.text="PIXEL COSMOS"
	title.position=Vector2(0,20)
	title.size=Vector2(630,46)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	overlay.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="STUDIO"
	subtitle.position=Vector2(0,74)
	subtitle.size=Vector2(630,26)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",20)
	overlay.add_child(subtitle)
	var footer:=ColorRect.new()
	footer.color=Color("08141ee8")
	footer.position=Vector2(0,456)
	footer.size=Vector2(630,44)
	overlay.add_child(footer)
	var detail:=Label.new()
	detail.text="PLANETS / VOXELS / SKYBOXES"
	detail.position=Vector2(0,464)
	detail.size=Vector2(630,26)
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(detail)
	await capture(cover,"cover.png")
	print("PRESSKIT_OK")
	quit()
