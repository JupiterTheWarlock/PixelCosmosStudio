extends SceneTree
const Store=preload("res://preset_store.gd")
const Schema=preload("res://parameters.gd")
func _initialize() -> void:
	var store:=Store.new()
	store.path="user://test_library_"+str(Time.get_ticks_usec())+".json"
	store.open()
	assert(store.error.is_empty())
	var original:=Schema.defaults("planet")
	assert(store.add_preset("测试 \"一\"", "planet", original))
	original.seed=123
	assert(store.data.presets[0].preset.parameters.seed!=123,"Preset must be a snapshot")
	assert(store.add_preset("Another", "sky", Schema.defaults("sky")))
	assert(store.set_locale("en"),"Third atomic write must replace an existing backup")
	var reopened:=Store.new()
	reopened.path=store.path
	reopened.open()
	assert(reopened.error.is_empty() and reopened.data.presets.size()==2)
	assert(reopened.data.settings.locale=="en")
	assert(Schema.validate("planet",reopened.data.presets[0].preset.parameters).has("parameters"))
	assert(reopened.remove_preset(reopened.data.presets[0].id))
	assert(reopened.data.presets.size()==1)
	var file:=FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var broken:=Store.new()
	broken.path=store.path
	broken.open()
	assert(not broken.error.is_empty())
	assert(not broken.set_locale("zh_CN"))
	assert(FileAccess.get_file_as_string(store.path)=="{broken","Corrupt library must not be overwritten")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(store.path+suffix): DirAccess.remove_absolute(store.path+suffix)
	print("STORAGE_TEST_OK: saved snapshots, reload, language, deletion, corrupt data protection")
	quit()
