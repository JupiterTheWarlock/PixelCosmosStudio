extends Node

const Archive=preload("res://web/export_archive.gd")
const Bridge=preload("res://web/files_bridge.gd")
var upload_callback: JavaScriptObject
var upload_target: Callable

func _bridge() -> JavaScriptObject:
	JavaScriptBridge.eval(Bridge.SOURCE,true)
	return JavaScriptBridge.get_interface("PixelCosmosFiles")

func pick_json(target: Callable) -> void:
	if upload_target.is_valid(): return
	upload_target=target
	upload_callback=JavaScriptBridge.create_callback(_uploaded)
	_bridge().pickJson(upload_callback)

func _uploaded(arguments: Array) -> void:
	var result: Variant=JSON.parse_string(str(arguments[0]))
	var target:=upload_target
	upload_target=Callable()
	if result is Dictionary and not result.get("cancelled",false): target.call(result)

func show_text(text: String, title: String) -> void:
	_bridge().showText(text,title,tr("可点击复制，或按 Ctrl+C / ⌘C 手动复制。"),tr("复制"),tr("已复制。"),tr("关闭"))

func offer_download(bytes: PackedByteArray, filename: String, mime: String) -> void:
	# An explicit click after generation keeps browser user activation valid.
	var dialog:=ConfirmationDialog.new()
	dialog.title="文件已准备好"
	dialog.ok_button_text="下载文件"
	dialog.cancel_button_text="关闭"
	dialog.dialog_text=tr("%s（%.1f MiB）\n点击下载；浏览器可能询问保存位置。")%[filename,bytes.size()/1048576.0]
	dialog.dialog_hide_on_ok=false
	get_parent().add_child(dialog)
	dialog.confirmed.connect(func() -> void: JavaScriptBridge.download_buffer(bytes,filename,mime))
	dialog.popup_hide.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(540,190))

func offer_archive(folder: String, filename: String) -> Error:
	var target:=folder+".zip"
	var error:=Archive.pack(folder,target)
	if error==OK:
		var input:=FileAccess.open(target,FileAccess.READ)
		if input==null: error=FileAccess.get_open_error()
		else:
			var bytes:=input.get_buffer(input.get_length())
			input.close()
			offer_download(bytes,filename,"application/zip")
	Archive.cleanup(folder)
	DirAccess.remove_absolute(target)
	return error
