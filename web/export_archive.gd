extends RefCounted

const ROOT="user://web_exports/"

static func workspace() -> String:
	var path:=ROOT+"job_%d_%d"%[Time.get_ticks_usec(),randi()]
	return path if DirAccess.make_dir_recursive_absolute(path)==OK else ""

static func pack(folder: String, target: String) -> Error:
	if not folder.begins_with(ROOT) or not target.begins_with(ROOT): return ERR_INVALID_PARAMETER
	var writer:=ZIPPacker.new()
	var error:=writer.open(target)
	if error!=OK: return error
	error=_append(writer,folder,"")
	var close_error:=writer.close()
	return error if error!=OK else close_error

static func _append(writer: ZIPPacker, folder: String, relative: String) -> Error:
	var directory:=DirAccess.open(folder)
	if directory==null: return DirAccess.get_open_error()
	for child in directory.get_directories():
		var error:=_append(writer,folder.path_join(child),relative.path_join(child))
		if error!=OK: return error
	for name in directory.get_files():
		var input:=FileAccess.open(folder.path_join(name),FileAccess.READ)
		if input==null: return FileAccess.get_open_error()
		var error:=writer.start_file(relative.path_join(name))
		if error!=OK: return error
		while input.get_position()<input.get_length():
			var chunk:=input.get_buffer(mini(1048576,input.get_length()-input.get_position()))
			if chunk.is_empty(): error=ERR_FILE_CANT_READ; break
			error=writer.write_file(chunk)
			if error!=OK: break
		input.close()
		var close_error:=writer.close_file()
		if error!=OK: return error
		if close_error!=OK: return close_error
	return OK

static func cleanup(folder: String) -> void:
	# Only delete an internally created job, never an arbitrary user path.
	if not folder.begins_with(ROOT+"job_") or ".." in folder: return
	var directory:=DirAccess.open(folder)
	if directory==null: return
	for child in directory.get_directories(): cleanup(folder.path_join(child))
	for name in directory.get_files(): directory.remove(name)
	DirAccess.remove_absolute(folder)
