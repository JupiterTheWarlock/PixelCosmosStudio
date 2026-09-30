extends RefCounted

# PixelSpace GUI/Theme.tres colors; PixelPlanets checkbox artwork.
const BACKGROUND=Color("08141e")
const INK=Color("0f2a3f")
const PAPER=Color("c3a38a")
const TEXT=Color("f6d6bd")
const HOVER=Color("4e4960")
const CJK_FONT=preload("res://assets/ui/NotoSansSC-Regular.otf")

static func apply_locale(theme: Theme) -> void:
	# Bundle CJK glyphs so the Web build does not depend on operating-system fonts.
	var font: Font=CJK_FONT if TranslationServer.get_locale().begins_with("zh") else load("res://assets/ui/slkscre.ttf")
	theme.default_font=font
	theme.set_font("title_font","Window",font)
	for type in ["TabContainer","TabBar"]:
		theme.set_font_size("font_size",type,14 if TranslationServer.get_locale().begins_with("zh") else 12)

static func box(fill: Color, border: Color, margin: int=6) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(1)
	style.content_margin_left=margin
	style.content_margin_right=margin
	style.content_margin_top=4
	style.content_margin_bottom=4
	return style

static func build() -> Theme:
	var theme:=Theme.new()
	var pixel_font: FontFile=load("res://assets/ui/slkscre.ttf")
	pixel_font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
	pixel_font.fallbacks=[CJK_FONT,ThemeDB.fallback_font]
	theme.default_font=pixel_font
	theme.default_font_size=16
	for type in ["Label","Button","CheckBox","CheckButton","OptionButton","LineEdit","TextEdit","PopupMenu","ItemList","TabBar","TabContainer","LinkButton"]:
		theme.set_color("font_color",type,TEXT)
		theme.set_color("font_hover_color",type,TEXT)
		theme.set_color("font_selected_color",type,INK)
		theme.set_color("font_disabled_color",type,Color("7d777a"))
		theme.set_color("font_focus_color",type,TEXT)
	for type in ["Button","OptionButton"]:
		theme.set_stylebox("normal",type,box(PAPER,INK))
		theme.set_stylebox("hover",type,box(HOVER,TEXT))
		theme.set_stylebox("pressed",type,box(PAPER,TEXT))
		theme.set_stylebox("disabled",type,box(BACKGROUND,HOVER))
		theme.set_color("font_color",type,INK)
		theme.set_color("font_pressed_color",type,INK)
		theme.set_color("font_focus_color",type,INK)
	for type in ["CheckBox","CheckButton"]:
		for state in ["font_color","font_pressed_color","font_hover_color","font_hover_pressed_color","font_focus_color"]: theme.set_color(state,type,TEXT)
		for state in ["normal","pressed"]: theme.set_stylebox(state,type,box(Color.TRANSPARENT,Color.TRANSPARENT,2))
		for state in ["hover","hover_pressed"]: theme.set_stylebox(state,type,box(HOVER,PAPER,2))
		theme.set_constant("h_separation",type,6)
	var checked: Texture2D=load("res://assets/ui/check.png")
	var unchecked: Texture2D=load("res://assets/ui/uncheck.png")
	for type in ["CheckBox","CheckButton","PopupMenu"]:
		for icon in ["checked","checked_disabled","radio_checked","on","on_disabled"]: theme.set_icon(icon,type,checked)
		for icon in ["unchecked","unchecked_disabled","radio_unchecked","off","off_disabled"]: theme.set_icon(icon,type,unchecked)
	for type in ["LineEdit","TextEdit","ItemList"]:
		theme.set_stylebox("normal",type,box(Color("050b10"),HOVER))
		theme.set_stylebox("read_only",type,box(BACKGROUND,HOVER))
		theme.set_stylebox("selected",type,box(PAPER,PAPER))
		theme.set_stylebox("selected_focus",type,box(PAPER,TEXT))
		theme.set_color("font_readonly_color",type,TEXT)
		theme.set_color("caret_color",type,TEXT)
		theme.set_color("selection_color",type,HOVER)
	# JSON remains a readable conventional font rather than decorative pixel text.
	theme.set_font("font","TextEdit",CJK_FONT)
	theme.set_stylebox("panel","PanelContainer",box(BACKGROUND,HOVER,8))
	theme.set_stylebox("panel","PopupMenu",box(BACKGROUND,PAPER))
	theme.set_stylebox("hover","PopupMenu",box(HOVER,TEXT))
	theme.set_stylebox("panel","AcceptDialog",box(BACKGROUND,PAPER,14))
	var window_border:=box(HOVER,PAPER,8)
	window_border.expand_margin_top=28
	theme.set_stylebox("embedded_border","Window",window_border)
	theme.set_color("title_color","Window",TEXT)
	theme.set_font("title_font","Window",pixel_font)
	theme.set_stylebox("panel","TabContainer",box(BACKGROUND,HOVER,8))
	for type in ["TabContainer","TabBar"]:
		theme.set_font_size("font_size",type,12)
		theme.set_stylebox("tab_selected",type,box(PAPER,TEXT,8))
		theme.set_stylebox("tab_unselected",type,box(BACKGROUND,HOVER,8))
		theme.set_stylebox("tab_hovered",type,box(HOVER,PAPER,8))
		theme.set_color("font_selected_color",type,INK)
		theme.set_color("font_unselected_color",type,TEXT)
	var track:=box(Color.BLACK,HOVER,0)
	track.content_margin_top=6
	track.content_margin_bottom=6
	theme.set_stylebox("slider","HSlider",track)
	theme.set_stylebox("grabber_area","HSlider",box(PAPER,PAPER,0))
	theme.set_stylebox("grabber_area_highlight","HSlider",box(TEXT,TEXT,0))
	theme.set_icon("grabber","HSlider",load("res://assets/ui/grabber.png"))
	theme.set_icon("grabber_highlight","HSlider",load("res://assets/ui/grabber-highlight.png"))
	for type in ["VScrollBar","HScrollBar"]:
		theme.set_stylebox("scroll",type,box(BACKGROUND,BACKGROUND,3))
		theme.set_stylebox("grabber",type,box(HOVER,PAPER,3))
		theme.set_stylebox("grabber_highlight",type,box(PAPER,TEXT,3))
		theme.set_stylebox("grabber_pressed",type,box(PAPER,TEXT,3))
	for state in ["normal","pressed"]: theme.set_stylebox(state,"ColorPickerButton",box(Color.BLACK,Color.BLACK,2))
	theme.set_stylebox("hover","ColorPickerButton",box(Color.BLACK,TEXT,2))
	var focus:=box(Color.TRANSPARENT,TEXT,0)
	focus.draw_center=false
	for type in ["Button","OptionButton","CheckBox","CheckButton","LineEdit","TextEdit","HSlider","ColorPickerButton","ItemList"]:
		theme.set_stylebox("focus",type,focus)
	theme.set_stylebox("panel","TooltipPanel",box(BACKGROUND,PAPER))
	theme.set_color("font_color","TooltipLabel",TEXT)
	theme.set_constant("separation","VBoxContainer",6)
	theme.set_constant("separation","HBoxContainer",6)
	return theme
