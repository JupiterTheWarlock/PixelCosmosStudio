extends RefCounted

func settled(studio: Control, domain: String) -> void:
	for i in 600:
		await studio.get_tree().process_frame
		var d: Dictionary = studio.pages[domain]
		if not d.busy and not d.dirty and d.timer.is_stopped(): return
	assert(false,"Preview did not settle")

func run(studio: Control) -> void:
	DirAccess.make_dir_recursive_absolute("res://exports/v2")
	var p: Dictionary = studio.pages.planet
	var s: Dictionary = studio.pages.sky
	for domain in ["planet","sky"]:
		var d: Dictionary = studio.pages[domain]
		for key in d.widgets:
			var widget: Control = d.widgets[key]
			if widget is SpinBox: assert(is_equal_approx(widget.value,float(d.parameters[key])),"Widget changed authored value "+key)
		for field in preload("res://parameters.gd").fields(domain):
			for child in d.rows[field[0]].get_children():
				if not child is HSlider: continue
				assert(is_equal_approx(child.value,.5),"Default not centered: "+field[0])
				assert(is_equal_approx(child.to_actual(.5),float(field[2])))
				assert(is_equal_approx(child.to_actual(0),float(field[3])))
				assert(is_equal_approx(child.to_actual(1),float(field[4])))
				var previous: float=float(field[3])
				for step_index in 101:
					var value: float=child.to_actual(step_index/100.0)
					assert(value>=previous,"Slider must be monotone")
					assert(value>=field[3] and value<=field[4])
					assert(absf(child.to_actual(child.to_position(value))-value)<.00001,"Roundtrip drift")
					previous=value
	for index in 2:
		studio.tabs.current_tab=index
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		studio.get_viewport().get_texture().get_image().save_png("res://exports/v2/"+("planet_tab.png" if index==0 else "sky_tab.png"))
	studio.tabs.current_tab=0
	p.settings_tabs.current_tab=2
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	studio.get_viewport().get_texture().get_image().save_png("res://exports/v2/advanced_tab.png")
	p.settings_tabs.current_tab=0
	var sky_seed: int = s.parameters.seed
	var row: Control = p.rows.rotation
	var slider: HSlider
	for child in row.get_children():
		if child is HSlider: slider=child
	slider.value=slider.to_position(3.5)
	await settled(studio,"planet")
	assert(is_equal_approx(p.result.parameters.rotation,3.5),"Slider should update without Generate")
	p.widgets.rotation.value=4.2
	await settled(studio,"planet")
	assert(is_equal_approx(slider.value,slider.to_position(4.2)),"Typed value must sync slider")
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.double_click=true
	event.pressed=true
	slider._gui_input(event)
	await settled(studio,"planet")
	assert(is_equal_approx(p.result.parameters.rotation,.2) and is_equal_approx(slider.value,.5),"Double click must reset actual value")
	p.widgets.noise_scale.value=8.0
	for button in p.widgets.noise_scale.get_parent().get_children():
		if button is Button: button.pressed.emit()
	await settled(studio,"planet")
	assert(is_equal_approx(p.result.parameters.noise_scale,4.292),"Reset must preserve precise default")
	assert(s.parameters.seed==sky_seed,"Independent sky settings")
	p.widgets.clouds_enabled.button_pressed=false
	await settled(studio,"planet")
	assert(p.result.node.get_node_or_null("CloudShell")==null,"Layer toggle should update preview")
	studio._changed("planet","seed",100)
	studio.generate("planet")
	studio._changed("planet","seed",200)
	await settled(studio,"planet")
	assert(p.result.parameters.seed==200,"Latest change during generation must win")
	studio._reset_colors("planet")
	assert(p.parameters.seed==200,"Palette reset must preserve seed")
	await settled(studio,"planet")
	studio.tabs.current_tab=1
	var schemes: Array = s.settings_tabs.find_children("*","Button",true,false)
	var selected: bool = false
	for button in schemes:
		if button.tooltip_text=="NYX8":
			button.pressed.emit()
			selected=true
			break
	assert(selected,"Original palette button missing")
	await settled(studio,"sky")
	var originals: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/space_palettes.json"))
	assert(s.result.parameters.palette0==originals[0].colors[1],"Palette did not reach generated output")
	assert(not s.export_button.disabled,"Current preview must be exportable")
	s.widgets.pixel_art.button_pressed=false
	await settled(studio,"sky")
	assert(not s.result.parameters.pixel_art,"Smooth toggle must reach the generated asset")
	assert(s.view.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"Smooth preview must not enlarge with nearest filtering")
	assert(studio.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Pixel UI retains its own filtering")
	await RenderingServer.frame_post_draw
	studio.get_viewport().get_texture().get_image().save_png("res://exports/v2/sky_smooth_tab.png")
	s.widgets.pixel_art.button_pressed=true
	await settled(studio,"sky")
	assert(s.view.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Pixel preview filtering must be restored")
	preload("res://asset_pipeline.gd").write_json("res://exports/v2/ui_report.json",{"passed":true,"default_centered_sliders":true,"monotone_full_range":true,"precise_defaults_preserved":true,"single_parameter_reset":true,"slider_updates":true,"latest_edit_wins":true,"layer_updates":true,"original_palette_click":true})
	print("UI_TEST_OK")
	studio.get_tree().quit()
