extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size=Vector2i(1200,760)
	var studio: Control=load("res://main.tscn").instantiate()
	studio.preset_store.path="user://test_settings_"+str(Time.get_ticks_usec())+".json"
	root.add_child(studio)
	for i in 600:
		await process_frame
		if studio.pages.has("sky") and not studio.pages.sky.result.is_empty(): break
	assert(not studio.pages.sky.result.is_empty())
	assert(studio.pages.planet.animate and studio.pages.planet.background_sky)
	assert(studio.pages.planet.motion_playing and studio.pages.sky.motion_playing)
	assert(studio.pages.planet.environment.environment.sky!=null)
	var library: Control=studio.pages.planet.library
	library.title_input.text="Saved in UI"
	library.save_current()
	assert(library.entries.item_count==1)
	var saved_seed: int=studio.pages.planet.parameters.seed
	studio.pages.planet.parameters.seed=1
	library.apply_selected()
	assert(studio.pages.planet.parameters.seed==saved_seed)
	assert(JSON.parse_string(library.inspector.text).parameters.seed==saved_seed)
	studio.settings_dialog.popup_centered()
	var selector: OptionButton=studio.settings_dialog.find_children("*","OptionButton",true,false)[0]
	selector.select(1)
	selector.item_selected.emit(1)
	assert(TranslationServer.get_locale().begins_with("en"))
	assert(studio.tabs.get_tab_title(0)=="Planets")
	assert(studio.preset_store.data.settings.locale=="en")
	assert(studio.tr("播放噪声")=="Play noise")
	DirAccess.make_dir_recursive_absolute("res://exports/settings")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/settings/settings_en.png")
	studio.settings_dialog.hide()
	studio.pages.planet.settings_tabs.current_tab=3
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://exports/settings/library_en.png")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(studio.preset_store.path+suffix): DirAccess.remove_absolute(studio.preset_store.path+suffix)
	print("SETTINGS_TEST_OK: default animation/background, library UI, inspect/apply, live language and saved preference")
	quit()
