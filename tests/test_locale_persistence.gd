extends SceneTree

const SAVE_PATH="user://test_locale_persistence.json"
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var verify: bool="--verify" in OS.get_cmdline_user_args()
	if not verify:
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(SAVE_PATH+suffix): DirAccess.remove_absolute(SAVE_PATH+suffix)
	root.size=Vector2i(1200,760)
	var studio: Control=load("res://main.tscn").instantiate()
	studio.preset_store.path=SAVE_PATH
	root.add_child(studio)
	for i in 600:
		await process_frame
		if studio.pages.has("sky") and not studio.pages.sky.result.is_empty(): break
	assert(not studio.pages.sky.result.is_empty())
	if not verify:
		assert(TranslationServer.get_locale().begins_with("en"),"First launch must default to English")
		var selector: OptionButton=studio.settings_dialog.find_children("*","OptionButton",true,false)[0]
		for language in [0,1,0]:
			selector.select(language)
			selector.item_selected.emit(language)
			await process_frame
			assert(studio.tr("播放噪声")==("播放噪声" if language==0 else "Play noise"),"Selected language must affect actual translations, not just locale ID")
			assert(studio.tr("界面语言")==("界面语言" if language==0 else "Language"))
			assert(studio.tr("像素 / 体素密度")==("像素 / 体素密度" if language==0 else "Pixel / voxel density"))
	assert(TranslationServer.get_locale().begins_with("zh"))
	assert(studio.tabs.get_tab_title(0)=="星球生成")
	assert(studio.tr("我的预设")=="我的预设")
	assert(studio.preset_store.data.settings.locale=="zh_CN")
	studio.settings_dialog.popup_centered()
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://exports/settings")
	root.get_texture().get_image().save_png("res://exports/settings/locale_zh_restart.png" if verify else "res://exports/settings/locale_zh_switch.png")
	if verify:
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(SAVE_PATH+suffix): DirAccess.remove_absolute(SAVE_PATH+suffix)
	print("LOCALE_RESTART_OK" if verify else "LOCALE_SWITCH_AND_SAVE_OK")
	quit()
