extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://dist/licenses")
	var license:=FileAccess.open("res://dist/licenses/Godot.txt",FileAccess.WRITE)
	license.store_string(Engine.get_license_text()+"\n\n"+JSON.stringify(Engine.get_license_info(),"\t"))
	license.close()
	var copyright:=FileAccess.open("res://dist/licenses/Godot-components.json",FileAccess.WRITE)
	copyright.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	copyright.close()
	quit()
