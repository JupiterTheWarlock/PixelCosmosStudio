extends AcceptDialog

signal locale_selected(locale: String)
var store: RefCounted
var status: Label

func setup(library: RefCounted) -> void:
	store=library
	title="设置"
	size=Vector2i(500,350)
	var list:=VBoxContainer.new()
	list.add_theme_constant_override("separation",14)
	add_child(list)
	var label:=Label.new()
	label.text="界面语言"
	list.add_child(label)
	var language:=OptionButton.new()
	language.add_item("简体中文")
	language.add_item("English")
	language.selected=1 if TranslationServer.get_locale().begins_with("en") else 0
	list.add_child(language)
	language.item_selected.connect(func(index: int) -> void:
		var locale: String="zh_CN" if index==0 else "en"
		TranslationServer.set_locale(locale)
		locale_selected.emit(locale)
		status.text="语言已保存。" if store.set_locale(locale) else "语言已切换，但未能保存；下次打开可能恢复默认。")
	var attribution:=Label.new()
	attribution.text="原项目与作者"
	list.add_child(attribution)
	for item in [["PixelPlanets · Deep-Fold","https://github.com/Deep-Fold/PixelPlanets"],["PixelSpace · Deep-Fold","https://github.com/Deep-Fold/PixelSpace"],["PixelSpace · JupiterTheWarlock fork","https://github.com/JupiterTheWarlock/PixelSpace"]]:
		var link:=LinkButton.new()
		link.text=item[0]
		link.uri=item[1]
		list.add_child(link)
	status=Label.new()
	status.custom_minimum_size=Vector2(460,48)
	status.add_theme_font_size_override("font_size",12)
	status.text="语言和预设保存在当前设备或浏览器中。"
	list.add_child(status)
