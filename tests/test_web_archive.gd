extends SceneTree

const Archive=preload("res://web/export_archive.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var folder:=Archive.workspace()
	assert(not folder.is_empty())
	DirAccess.make_dir_recursive_absolute(folder.path_join("frames/0000"))
	var entries: Dictionary={"preset.json":"{\"name\":\"星球\"}".to_utf8_buffer(),"frames/0000/base_color_px.png":PackedByteArray([0,255,1,128,42]),"large.bin":PackedByteArray()}
	entries["large.bin"].resize(2097161)
	entries["large.bin"].fill(73)
	for name in entries:
		var file:=FileAccess.open(folder.path_join(name),FileAccess.WRITE)
		file.store_buffer(entries[name])
		file.close()
	var target:=folder+".zip"
	assert(Archive.pack(folder,target)==OK)
	var reader:=ZIPReader.new()
	assert(reader.open(target)==OK)
	assert(reader.get_files().size()==entries.size())
	for name in entries: assert(reader.read_file(name)==entries[name],"ZIP content roundtrip: "+name)
	reader.close()
	assert(Archive.pack("res://",target)==ERR_INVALID_PARAMETER)
	Archive.cleanup(folder)
	assert(not DirAccess.dir_exists_absolute(folder))
	DirAccess.remove_absolute(target)
	print("WEB_ARCHIVE_OK: nested files, UTF-8, binary content, chunked reads, cleanup")
	quit()
