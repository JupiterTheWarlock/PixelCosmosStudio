extends RefCounted

const FILE_PATH = "user://preset_library.json"
const WEB_SCRIPT = preload("res://assets/browser_storage.gd")
var path: String = FILE_PATH
var data: Dictionary = {"format":"pixel-cosmos-library","version":1,"settings":{"locale":"en"},"presets":[]}
var error: String = ""

func open() -> void:
	error=""
	var raw: String = ""
	if OS.has_feature("web"):
		var response: Variant = JSON.parse_string(str(JavaScriptBridge.eval(WEB_SCRIPT.SOURCE+";PixelCosmosStorage.read()",true)))
		if not response is Dictionary or not response.get("ok",false):
			error = "浏览器未允许保存数据。可以复制 JSON 备份，允许站点存储后重试。"
			return
		raw = str(response.get("value",""))
	else:
		var read_path: String=path
		if not FileAccess.file_exists(read_path) and FileAccess.file_exists(path+".bak"): read_path=path+".bak"
		if not FileAccess.file_exists(read_path): return
		var file := FileAccess.open(read_path,FileAccess.READ)
		if file==null:
			error = "无法读取预设库，原文件未改动。"
			return
		raw = file.get_as_text()
	if raw.is_empty(): return
	var parser:=JSON.new()
	var parsed: Variant = parser.data if parser.parse(raw)==OK else null
	if not parsed is Dictionary or parsed.get("format")!="pixel-cosmos-library" or parsed.get("version")!=1 or not parsed.get("presets") is Array or not parsed.get("settings") is Dictionary:
		error = "预设库格式错误，原数据未覆盖。请备份后修复。"
		return
	for entry in parsed.presets:
		if not entry is Dictionary or not entry.get("name") is String or not entry.get("id") is String or not entry.get("preset") is Dictionary:
			error = "预设库格式错误，原数据未覆盖。请备份后修复。"
			return
	data=parsed

func persist(next: Dictionary) -> bool:
	if not error.is_empty(): return false
	var raw := JSON.stringify(next,"\t")
	if OS.has_feature("web"):
		var response: Variant = JSON.parse_string(str(JavaScriptBridge.eval(WEB_SCRIPT.SOURCE+";PixelCosmosStorage.write("+JSON.stringify(raw)+")",true)))
		if not response is Dictionary or not response.get("ok",false): return false
	else:
		var temp := path+".tmp"
		var file := FileAccess.open(temp,FileAccess.WRITE)
		if file==null: return false
		file.store_string(raw)
		file.flush()
		var write_error := file.get_error()
		file.close()
		if write_error!=OK: return false
		# Keep the previous successful library until its replacement is complete.
		if FileAccess.file_exists(path):
			if FileAccess.file_exists(path+".bak") and DirAccess.remove_absolute(path+".bak")!=OK: return false
			if DirAccess.rename_absolute(path,path+".bak")!=OK: return false
		if DirAccess.rename_absolute(temp,path)!=OK:
			if FileAccess.file_exists(path+".bak"): DirAccess.rename_absolute(path+".bak",path)
			return false
	data=next
	return true

func add_preset(title: String, domain: String, parameters: Dictionary) -> bool:
	var next := data.duplicate(true)
	next.presets.append({"id":str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec()),"name":title.strip_edges(),"saved_at":Time.get_datetime_string_from_system(),"preset":{"format":"pixel-cosmos-preset","version":2,"domain":domain,"parameters":parameters.duplicate(true)}})
	return persist(next)

func remove_preset(id: String) -> bool:
	var next := data.duplicate(true)
	for i in range(next.presets.size()-1,-1,-1):
		if next.presets[i].id==id: next.presets.remove_at(i)
	return persist(next)

func set_locale(locale: String) -> bool:
	var next := data.duplicate(true)
	next.settings.locale=locale
	return persist(next)
