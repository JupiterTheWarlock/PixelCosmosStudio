extends VBoxContainer

var studio: Control
var store: RefCounted
var domain: String
var title_input: LineEdit
var entries: ItemList
var inspector: TextEdit
var message: Label
var current: Dictionary = {}

func setup(owner_studio: Control, library: RefCounted, page: String) -> void:
	studio=owner_studio
	store=library
	domain=page
	var heading := Label.new()
	heading.text="我的预设"
	add_child(heading)
	var row := HBoxContainer.new()
	add_child(row)
	title_input=LineEdit.new()
	title_input.placeholder_text="预设名称"
	title_input.max_length=80
	title_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(title_input)
	button(row,"保存当前",save_current)
	entries=ItemList.new()
	entries.custom_minimum_size.y=110
	entries.item_selected.connect(select_entry)
	add_child(entries)
	var actions := HBoxContainer.new()
	add_child(actions)
	button(actions,"应用",apply_selected)
	button(actions,"复制 JSON",func() -> void:
		if not inspector.text.is_empty(): DisplayServer.clipboard_set(inspector.text))
	button(actions,"删除",confirm_remove)
	inspector=TextEdit.new()
	inspector.editable=false
	inspector.custom_minimum_size.y=160
	inspector.add_theme_font_size_override("font_size",12)
	add_child(inspector)
	message=Label.new()
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(message)
	message.text="保存在此浏览器；清理站点数据会删除预设，请保留 JSON 备份。" if OS.has_feature("web") else "保存在这台电脑，重开工具后仍可使用。"
	if not store.error.is_empty(): message.text=store.error
	# JSON paste works on desktop and Web without depending on a file picker.
	button(self,"粘贴 JSON 导入…",open_import)
	button(self,"重新读取预设库",func() -> void:
		store.open()
		refresh()
		message.text="预设库已重新读取。" if store.error.is_empty() else store.error)
	refresh()

func button(parent: Node, title: String, action: Callable) -> Button:
	var b:=Button.new()
	b.text=title
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func refresh() -> void:
	entries.clear()
	current={}
	inspector.text=""
	for item in store.data.presets:
		if item.preset.get("domain")==domain:
			entries.add_item(item.name)
			entries.set_item_metadata(entries.item_count-1,item)

func select_entry(index: int) -> void:
	current=entries.get_item_metadata(index)
	inspector.text=JSON.stringify(current.preset,"\t")

func save_current() -> void:
	var title:=title_input.text.strip_edges()
	if title.is_empty():
		message.text="请先填写预设名称。"
		return
	if not store.add_preset(title,domain,studio.pages[domain].parameters):
		message.text=store.error if not store.error.is_empty() else "保存失败：存储不可用或空间不足，请复制 JSON 备份后重试。"
		inspector.text=JSON.stringify({"format":"pixel-cosmos-preset","version":2,"domain":domain,"parameters":studio.pages[domain].parameters},"\t")
		return
	refresh()
	entries.select(entries.item_count-1)
	select_entry(entries.item_count-1)
	message.text="预设已保存。"

func apply_selected() -> void:
	if current.is_empty(): return
	var error: String=studio.apply_preset_data(domain,current.preset)
	message.text="预设已应用。" if error.is_empty() else error

func confirm_remove() -> void:
	if current.is_empty(): return
	var id: String=current.id
	var dialog:=ConfirmationDialog.new()
	dialog.dialog_text=tr("删除选中的预设？")+"\n"+current.name
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		if store.remove_preset(id): refresh(); message.text="预设已删除。"
		else: message.text="删除失败，原预设保留。"
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func open_import() -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title="粘贴 JSON 导入"
	dialog.size=Vector2i(620,440)
	var input:=TextEdit.new()
	input.custom_minimum_size=Vector2(580,340)
	input.placeholder_text="在这里粘贴完整的预设 JSON"
	dialog.add_child(input)
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		var parsed: Variant=JSON.parse_string(input.text)
		var error: String=studio.apply_preset_data(domain,parsed)
		message.text="预设已应用；填写名称后可保存到预设库。" if error.is_empty() else error
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
