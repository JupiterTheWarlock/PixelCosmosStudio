extends Control

const Schema = preload("res://parameters.gd")
const Pipeline = preload("res://asset_pipeline.gd")
const Motion = preload("res://noise_motion.gd")
const PIXEL_LIT = preload("res://adapters/godot/pixel_lit.gdshader")
var pages: Dictionary = {}
var updating: bool = false
var tabs: TabContainer
var preset_store = preload("res://preset_store.gd").new()
var settings_dialog: AcceptDialog

func _ready() -> void:
	preload("res://localization.gd").install()
	if not OS.get_cmdline_user_args().is_empty():
		if "--smoke" in OS.get_cmdline_user_args() or "--ui-smoke" in OS.get_cmdline_user_args() or "--motion-smoke" in OS.get_cmdline_user_args(): preset_store.path="user://test_library.json"
	preset_store.open()
	TranslationServer.set_locale(str(preset_store.data.settings.get("locale","en")))
	tabs = TabContainer.new()
	tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabs.offset_left = 16
	tabs.offset_top = 52
	tabs.offset_right = -16
	tabs.offset_bottom = -12
	add_child(tabs)
	settings_dialog=preload("res://ui/studio_settings.gd").new()
	add_child(settings_dialog)
	settings_dialog.setup(preset_store)
	settings_dialog.locale_selected.connect(func(_locale: String) -> void: _refresh_tab_titles())
	var settings_button:=Button.new()
	settings_button.text="设置"
	add_child(settings_button)
	settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	settings_button.offset_left=-112
	settings_button.offset_right=-16
	settings_button.offset_top=10
	settings_button.offset_bottom=42
	settings_button.pressed.connect(func() -> void: settings_dialog.popup_centered())
	for domain in ["planet","sky"]:
		pages[domain] = {"parameters":Schema.defaults(domain),"widgets":{},"rows":{},"result":{},"busy":false,"dirty":true,"yaw":0.0,"pitch":0.0,"distance":3.5}
		_build_page(domain)
	_refresh_tab_titles()
	await generate("planet")
	await generate("sky")
	update_background()
	if "--smoke" in OS.get_cmdline_user_args():
		await load("res://tests/test_studio.gd").new().run(self)
	elif "--ui-smoke" in OS.get_cmdline_user_args():
		await load("res://tests/test_ui.gd").new().run(self)
	elif "--motion-smoke" in OS.get_cmdline_user_args():
		await load("res://tests/test_motion.gd").new().run(self)

func _build_page(domain: String) -> void:
	var page := HBoxContainer.new()
	page.name = "星球生成" if domain=="planet" else "星空生成"
	page.add_theme_constant_override("separation",18)
	tabs.add_child(page)
	# Match the source tools: large preview on the left, compact settings on the right.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(right)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 410
	page.add_child(panel)
	var inset := MarginContainer.new()
	for side in ["left","right","top","bottom"]: inset.add_theme_constant_override("margin_"+side,10)
	panel.add_child(inset)
	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation",8)
	inset.add_child(settings)
	var settings_tabs := TabContainer.new()
	settings_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings.add_child(settings_tabs)
	pages[domain].settings_tabs = settings_tabs
	var common: VBoxContainer = _settings_page(settings_tabs,"常用")
	var motion: VBoxContainer = _settings_page(settings_tabs,"动态")
	var advanced: VBoxContainer = _settings_page(settings_tabs,"高级")
	var saved: VBoxContainer = _settings_page(settings_tabs,"配置")
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = .25
	timer.timeout.connect(func() -> void: generate(domain))
	add_child(timer)
	pages[domain].timer = timer
	var used: Array[String] = []
	var fields: Dictionary = {}
	for field in Schema.fields(domain): fields[field[0]]=field
	var primary: Array = ["type","seed","pixels","rotation"] if domain=="planet" else ["seed","face_size"]
	if domain=="sky":
		_button(common,"生成新星空",func() -> void: _new_seed(domain))
	for key in primary:
		_add_field(domain,common,fields[key])
		used.append(key)
		if key=="seed": _button(pages[domain].widgets[key].get_parent(),"随机",func() -> void: _new_seed(domain))
	if domain=="sky": _space_schemes(common)
	_label(common,"配色 · 点击色块修改")
	var colors := GridContainer.new()
	colors.columns = 9 if domain=="sky" else 6
	common.add_child(colors)
	for field in Schema.fields(domain):
		if not field[2] is String: continue
		var key: String = field[0]
		var color := ColorPickerButton.new()
		color.custom_minimum_size = Vector2(34,30)
		color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color.edit_alpha = false
		color.tooltip_text = field[1]
		color.color_changed.connect(func(value: Color) -> void: _changed(domain,key,value.to_html(false)))
		colors.add_child(color)
		pages[domain].widgets[key]=color
		pages[domain].rows[key]=color
		used.append(key)
	var color_actions := HBoxContainer.new()
	common.add_child(color_actions)
	_button(color_actions,"随机配色",func() -> void: _random_colors(domain))
	_button(color_actions,"重置配色",func() -> void: _reset_colors(domain))
	_button(color_actions,"导入",func() -> void: _preset_dialog(domain,true,true))
	_button(color_actions,"导出",func() -> void: _preset_dialog(domain,false,true))
	_label(common,"图层与显示")
	var switches := GridContainer.new()
	switches.columns = 2
	common.add_child(switches)
	var toggles: Array = ["surface_enabled","clouds_enabled","rings_enabled","voxel","pixel_art","dither"] if domain=="planet" else ["stars_enabled","bright_enabled","dust_enabled","nebula_enabled","decor_enabled","reduce_background","pixel_art","transparent"]
	for key in toggles:
		var check := CheckBox.new()
		check.text = fields[key][1]
		check.toggled.connect(func(value: bool) -> void: _changed(domain,key,value))
		switches.add_child(check)
		pages[domain].widgets[key]=check
		pages[domain].rows[key]=check
		used.append(key)
	if domain=="planet":
		_add_field(domain,common,fields.face_size)
		used.append("face_size")
	var group: String = ""
	for field in Schema.fields(domain):
		if field[0] in used: continue
		if field[6]=="动态噪声":
			_add_field(domain,motion,field)
			continue
		if group!=field[6]:
			group=field[6]
			_label(advanced,group)
		_add_field(domain,advanced,field)
	_label(motion,"云层形变、海水流动、气态扰动" if domain=="planet" else "星云演化，星点位置保持不变")
	_label(motion,"时长越长变化越慢；次数越多变化越快。\n动画导出仅包含噪声变化，不包含自转或灯光。")
	_button(motion,"复制动态实现说明",func() -> void:
		DisplayServer.clipboard_set(Motion.context(domain,pages[domain].parameters))
		pages[domain].status.text="已复制算法、参数和接入说明。")
	_button(motion,"导出循环动画…",func() -> void: _animation_dialog(domain))
	var export_info := Label.new()
	export_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	export_info.add_theme_font_size_override("font_size",12)
	motion.add_child(export_info)
	pages[domain].export_info=export_info
	var cancel_button: Button=_button(motion,"停止动画导出",func() -> void: pages[domain].cancel_export=true)
	cancel_button.visible=false
	pages[domain].cancel_button=cancel_button
	_label(saved,"保存完整配置，之后继续调整")
	_button(saved,"保存配置…",func() -> void: _preset_dialog(domain,false,false))
	_button(saved,"载入配置…",func() -> void: _preset_dialog(domain,true,false))
	_button(saved,"重置全部参数",func() -> void:
		pages[domain].parameters = Schema.type_defaults(pages[domain].parameters.type) if domain=="planet" else Schema.defaults(domain)
		_sync_widgets(domain)
		_dirty(domain))
	_label(saved,"参数修改后自动更新预览。\n拖动滑条时稍停即可看到结果。")
	var library:=preload("res://ui/preset_library.gd").new()
	saved.add_child(library)
	saved.move_child(library,0)
	library.setup(self,preset_store,domain)
	pages[domain].library=library
	var actions := HBoxContainer.new()
	settings.add_child(actions)
	_button(actions,"重新生成",func() -> void: generate(domain))
	var export_button: Button = _button(actions,"导出静态资产…",func() -> void: _export_dialog(domain))
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages[domain].export_button = export_button
	var hint := Label.new()
	hint.text = "拖动绕星球观察 · 滚轮缩放 · 灯光实时更新" if domain=="planet" else "拖动环视完整天空 · 与星球参数互不影响"
	right.add_child(hint)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(560,420)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.position.z = 3.5 if domain=="planet" else 0.0
	camera.fov = 52
	world.add_child(camera)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("121925")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .65
	env.environment.ambient_light_sky_contribution = 0.0
	env.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	world.add_child(env)
	var view := TextureRect.new()
	view.texture = viewport.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(view)
	view.gui_input.connect(func(event: InputEvent) -> void: _view_input(domain,event))
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 52
	right.add_child(status)
	var pipeline := Pipeline.new()
	add_child(pipeline)
	pages[domain].merge({"viewport":viewport,"world":world,"camera":camera,"environment":env,"view":view,"status":status,"pipeline":pipeline})
	_motion_controls(domain,right)
	if domain=="planet": _lighting_controls(right)
	_sync_widgets(domain)

func _add_field(domain: String, parent: Control, field: Array) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation",0)
	parent.add_child(row)
	var line := HBoxContainer.new()
	row.add_child(line)
	var label := Label.new()
	label.text = field[1]
	label.custom_minimum_size.x = 125
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.tooltip_text = field[1]
	label.add_theme_font_size_override("font_size",13)
	line.add_child(label)
	var key: String = field[0]
	var control: Control
	if key=="type":
		var option := OptionButton.new()
		for name in Schema.TYPES: option.add_item(name)
		option.item_selected.connect(func(value: int) -> void: _type_changed(value))
		control = option
	elif field[2] is bool:
		var check := CheckBox.new()
		check.toggled.connect(func(value: bool) -> void: _changed(domain,key,value))
		control = check
	elif field[2] is String:
		var color := ColorPickerButton.new()
		color.custom_minimum_size = Vector2(96,28)
		color.edit_alpha = false
		color.color_changed.connect(func(value: Color) -> void: _changed(domain,key,value.to_html(false)))
		control = color
	else:
		var spin := SpinBox.new()
		spin.allow_greater = key in Schema.UNBOUNDED
		spin.allow_lesser = key in Schema.UNBOUNDED
		spin.min_value = field[3]
		spin.max_value = field[4]
		spin.step = field[5]
		# Preserve precise authored defaults, rather than rounding on first display.
		if field[2] is float:
			var decimals: int=str(field[2]).get_slice(".",1).length()
			spin.step=minf(spin.step,pow(10.0,-decimals))
		spin.custom_minimum_size.x = 92
		var numerical_seed: bool=key=="seed" or key.ends_with("_seed")
		var interior_default: bool=float(field[2])>float(field[3]) and float(field[2])<float(field[4])
		if not numerical_seed and key!="face_size" and not key in Schema.UNBOUNDED and interior_default:
			var slider := preload("res://parameter_slider.gd").new()
			slider.setup(field)
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(slider)
			slider.value_changed.connect(func(position: float) -> void: spin.value=slider.to_actual(position))
			spin.value_changed.connect(func(actual: float) -> void: slider.set_value_no_signal(slider.to_position(actual)))
		else:
			spin.tooltip_text=tr("输入实际数值。默认 %s；范围 %s ～ %s。")%[str(field[2]),str(field[3]),str(field[4])]
		if key in Schema.UNBOUNDED: spin.tooltip_text="原作未设置大小的上下限，可输入数值。"
		spin.value_changed.connect(func(value: float) -> void: _changed(domain,key,int(value) if field[2] is int else value))
		control = spin
	line.add_child(control)
	if control is SpinBox and key!="seed":
		var reset: Button=_button(line,"↺",func() -> void:
			var baseline: Dictionary=Schema.type_defaults(int(pages[domain].parameters.type)) if domain=="planet" else Schema.defaults(domain)
			control.value=baseline[key]
			_changed(domain,key,baseline[key]))
		reset.tooltip_text=tr("恢复默认：")+str(field[2])
	pages[domain].widgets[key] = control
	pages[domain].rows[key] = row

func _changed(domain: String, key: String, value: Variant) -> void:
	if updating: return
	pages[domain].parameters[key] = value
	_update_export_info(domain)
	_dirty(domain)

func _type_changed(value: int) -> void:
	if updating: return
	var previous: Dictionary = pages.planet.parameters
	var next: Dictionary = Schema.type_defaults(value)
	for key in ["seed","face_size","pixels","voxel","radius"]: next[key] = previous[key]
	for field in Motion.fields("planet"): next[field[0]]=previous[field[0]]
	pages.planet.parameters = next
	_sync_widgets("planet")
	_dirty("planet")

func _dirty(domain: String) -> void:
	pages[domain].dirty = true
	pages[domain].export_button.disabled = true
	pages[domain].status.text = "正在更新预览…"
	if not "--smoke" in OS.get_cmdline_user_args(): pages[domain].timer.start()

func _sync_widgets(domain: String) -> void:
	updating = true
	var p: Dictionary = pages[domain].parameters
	var authored_fields: Dictionary={}
	for field in Schema.fields(domain,int(p.get("type",2))): authored_fields[field[0]]=field
	for key in pages[domain].widgets:
		var widget: Control = pages[domain].widgets[key]
		if widget is OptionButton: widget.selected = p[key]
		elif widget is CheckBox: widget.button_pressed = p[key]
		elif widget is ColorPickerButton: widget.color = Color(p[key])
		else:
			for child in pages[domain].rows[key].get_children():
				if child is HSlider: child.setup(authored_fields[key])
			widget.value = p[key]
			for child in pages[domain].rows[key].get_children():
				if child is HSlider: child.set_value_no_signal(child.to_position(p[key]))
	if domain=="planet":
		var applicability: Dictionary = {"land_cutoff":[0,2],"land_enabled":[0,2],"water_enabled":[0,2],"river_cutoff":[0],"rivers_enabled":[0],"lakes_enabled":[0,6],"lake_cutoff":[0,6],"craters_enabled":[3,7],"crater_scale":[3,7],"crater_depth":[3,7],"ice_coverage":[6],"lava_cutoff":[7],"bands":[4,5],"swirl":[4,5]}
		for key in applicability: pages[domain].rows[key].visible = p.type in applicability[key]
	updating = false
	_update_export_info(domain)
	if domain=="planet":
		for key in ["gas_motion","gas_strength","gas_cycles"]: pages.planet.rows[key].visible=p.type in [4,5]
		for key in ["water_motion","water_strength","water_cycles"]: pages.planet.rows[key].visible=p.type in [0,2,6]

func _update_export_info(domain: String) -> void:
	if not pages[domain].has("export_info"): return
	var p: Dictionary=pages[domain].parameters
	var layers: int=2 if domain=="planet" and p.clouds_enabled else 1
	var mib: float=float(p.face_size*p.face_size*6*4*p.noise_frames*layers)/1048576.0
	pages[domain].export_info.text=tr("%.1f 帧/秒 · %d 张 PNG\n未压缩约 %.0f MiB，PNG 实际大小取决于内容。\n静态导出固定为第 0 秒；动画不写入 GLB 轨道。")%[float(p.noise_frames)/p.noise_duration,p.noise_frames*6*layers,mib]

func _button(parent: Control, text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callable)
	parent.add_child(button)
	return button

func _number(parent: Control, text: String, value: float, low: float, high: float, step_value: float, callable: Callable) -> SpinBox:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",12)
	parent.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = step_value
	spin.value = value
	spin.value_changed.connect(callable)
	parent.add_child(spin)
	return spin

func _lighting_controls(parent: Control) -> void:
	var d: Dictionary = pages.planet
	var omni := OmniLight3D.new()
	omni.omni_range = 20.0
	omni.omni_attenuation = .35
	omni.light_energy = 1.0
	d.world.add_child(omni)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.0
	sun.visible = false
	d.world.add_child(sun)
	d.merge({"omni":omni,"sun":sun,"light_azimuth":-35.0,"light_elevation":30.0,"light_mode":0,"ambient":.65,"energy":1.0,"animate":not ("--smoke" in OS.get_cmdline_user_args() or "--ui-smoke" in OS.get_cmdline_user_args() or "--motion-smoke" in OS.get_cmdline_user_args()),"style":false,"levels":4.0,"style_dither":.08,"background_sky":true})
	var row := HBoxContainer.new()
	parent.add_child(row)
	var kind := OptionButton.new()
	kind.add_item("点光源")
	kind.add_item("方向光")
	kind.item_selected.connect(func(v: int) -> void: d.light_mode = v; update_lighting())
	row.add_child(kind)
	_number(row,"环境光",.65,0,2,.05,func(v: float) -> void: d.ambient=v; update_lighting())
	_number(row,"灯光",1.0,0,5,.1,func(v: float) -> void: d.energy=v; update_lighting())
	_number(row,"方位 °",-35,-180,180,5,func(v: float) -> void: d.light_azimuth=v; update_lighting())
	_number(row,"高度 °",30,-85,85,5,func(v: float) -> void: d.light_elevation=v; update_lighting())
	var options := HBoxContainer.new()
	parent.add_child(options)
	for pair in [["animate","播放自转/云层"],["style","像素分段光照"],["background_sky","使用星空背景"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		var key: String = pair[0]
		check.button_pressed=d[key]
		check.toggled.connect(func(v: bool) -> void:
			d[key]=v
			if key=="style": apply_style()
			if key=="background_sky": update_background())
		options.add_child(check)
	var style_row := HBoxContainer.new()
	parent.add_child(style_row)
	_number(style_row,"明暗层数",4,2,8,1,func(v: float) -> void: d.levels=v; apply_style())
	_number(style_row,"光照点阵",.08,0,.3,.01,func(v: float) -> void: d.style_dither=v; apply_style())
	update_lighting()

func update_lighting() -> void:
	var d: Dictionary = pages.planet
	var r: float = d.result.get("parameters",d.parameters).radius
	var az: float = deg_to_rad(d.light_azimuth)
	var el: float = deg_to_rad(d.light_elevation)
	d.omni.position = Vector3(sin(az)*cos(el),sin(el),cos(az)*cos(el))*4.0*r
	d.omni.omni_range = 20.0*r
	d.sun.position = d.omni.position
	d.sun.look_at(Vector3.ZERO,Vector3.UP)
	d.omni.visible = d.light_mode==0
	d.sun.visible = d.light_mode==1
	d.omni.light_energy = d.energy
	d.sun.light_energy = d.energy
	d.environment.environment.ambient_light_energy = d.ambient

func update_background() -> void:
	var env: Environment = pages.planet.environment.environment
	if pages.planet.background_sky and not pages.sky.result.is_empty():
		env.sky = pages.sky.environment.environment.sky
		env.background_mode = Environment.BG_SKY
	else:
		env.background_mode = Environment.BG_COLOR
		env.sky = null

func apply_style() -> void:
	var d: Dictionary = pages.planet
	if d.result.is_empty(): return
	for child in d.result.node.get_children():
		for i in child.mesh.get_surface_count():
			if not d.style:
				child.set_surface_override_material(i,null)
				continue
			var source: StandardMaterial3D = child.mesh.surface_get_material(i)
			var mat := ShaderMaterial.new()
			mat.shader = PIXEL_LIT
			mat.set_shader_parameter("base_color",source.albedo_texture)
			mat.set_shader_parameter("textured",source.albedo_texture!=null)
			mat.set_shader_parameter("vertex_colored",source.vertex_color_use_as_albedo)
			mat.set_shader_parameter("alpha_clip",source.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
			mat.set_shader_parameter("levels",d.levels)
			mat.set_shader_parameter("dither_strength",d.style_dither)
			child.set_surface_override_material(i,mat)
	_apply_motion("planet")

func generate(domain: String) -> void:
	var d: Dictionary = pages[domain]
	if d.busy: return
	d.timer.stop()
	d.busy = true
	d.export_button.disabled = true
	d.status.text = "正在生成…"
	var snapshot: Dictionary = d.parameters.duplicate(true)
	var result: Dictionary = await d.pipeline.generate(domain,snapshot)
	if result.has("error"):
		d.busy = false
		d.dirty = true
		d.status.text = result.error
		return
	if domain=="planet":
		if not d.result.is_empty():
			d.world.remove_child(d.result.node)
			d.result.node.queue_free()
		d.world.add_child(result.node)
		d.result = result
		d.camera.position = Vector3(0,0,d.distance*snapshot.radius)
		_orbit_camera(domain)
		update_lighting()
		apply_style()
	else:
		d.result = result
		d.environment.environment.sky = result.sky
		d.environment.environment.background_mode = Environment.BG_SKY
		_apply_motion("sky")
		update_background()
	d.busy = false
	d.dirty = d.parameters!=snapshot
	d.export_button.disabled = d.dirty
	d.status.text = (tr("已生成 · 种子 %d · 本色资产，实时光照") if domain=="planet" else tr("已生成 · 种子 %d · 六面天空连续采样")) % snapshot.seed
	if d.dirty:
		d.status.text = "正在应用最新参数…"
		if not "--smoke" in OS.get_cmdline_user_args(): d.timer.start()
	if domain=="planet" and result.node.get_child_count()==0:
		d.export_button.disabled = true
		d.status.text = "所有星球图层都已关闭，请至少开启表面、云层或星环再导出。"

func _orbit_camera(domain: String) -> void:
	var d: Dictionary = pages[domain]
	if domain=="sky": d.camera.rotation = Vector3(d.pitch,d.yaw,0)
	else:
		var r: float = d.result.get("parameters",d.parameters).radius
		d.camera.position = Vector3(sin(d.yaw)*cos(d.pitch),sin(d.pitch),cos(d.yaw)*cos(d.pitch))*d.distance*r
		d.camera.look_at(Vector3.ZERO,Vector3.UP)

func _view_input(domain: String, event: InputEvent) -> void:
	var d: Dictionary = pages[domain]
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		# A sky camera turns in place; dragging right must move the sky right.
		d.yaw += event.relative.x*.008*(1.0 if domain=="sky" else -1.0)
		d.pitch = clampf(d.pitch+event.relative.y*.008,-1.45,1.45)
		_orbit_camera(domain)
	if event is InputEventMouseButton and event.pressed and domain=="planet":
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: d.distance=maxf(2,d.distance-.2)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: d.distance=minf(10,d.distance+.2)
		_orbit_camera(domain)

func _process(delta: float) -> void:
	for domain in pages:
		var page: Dictionary = pages[domain]
		if not page.has("motion_materials") or page.result.is_empty(): continue
		var visible_page: bool=tabs.current_tab==(["planet","sky"].find(domain)) or (domain=="sky" and tabs.current_tab==0 and pages.planet.get("background_sky",false))
		if page.motion_playing and visible_page:
			page.noise_time=fposmod(page.noise_time+delta,page.parameters.noise_duration)
			_set_motion_time(domain,page.noise_time)
	if not pages.has("planet"): return
	var d: Dictionary = pages.planet
	if d.get("animate",false) and not d.result.is_empty():
		var p: Dictionary = d.result.parameters
		d.result.node.rotate_y(deg_to_rad(p.rotation_speed)*delta)
		var cloud: Node3D = d.result.node.get_node_or_null("CloudShell")
		if cloud: cloud.rotate_y(deg_to_rad(p.cloud_speed)*delta)

func _random_colors(domain: String) -> void:
	var hue: float = randf()
	var index: int = 0
	for field in Schema.fields(domain):
		if field[2] is String:
			pages[domain].parameters[field[0]] = Color.from_hsv(fposmod(hue+index*.07,1.0),.55,.35+.6*float(index%4)/3.0).to_html(false)
			index += 1
	_sync_widgets(domain)
	_dirty(domain)

func _dialog(title: String, mode: FileDialog.FileMode, callback: Callable) -> void:
	var dialog := FileDialog.new()
	dialog.title = title
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = mode
	dialog.size = Vector2i(850,520)
	if mode!=FileDialog.FILE_MODE_OPEN_DIR: dialog.filters = PackedStringArray(["*.json ; JSON 配置"])
	add_child(dialog)
	if mode==FileDialog.FILE_MODE_OPEN_DIR:
		dialog.dir_selected.connect(func(path: String) -> void: callback.call(path); dialog.queue_free())
	else: dialog.file_selected.connect(func(path: String) -> void: callback.call(path); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _export_dialog(domain: String) -> void:
	var d: Dictionary = pages[domain]
	if d.busy or d.dirty or d.result.is_empty(): return
	_dialog("选择导出位置",FileDialog.FILE_MODE_OPEN_DIR,func(path: String) -> void:
		var folder: String = path.path_join(domain+"_"+str(d.result.parameters.seed)+"_"+str(Time.get_ticks_msec()))
		var error: Error = Pipeline.export_assets(d.result,folder)
		d.status.text = tr("导出完成：")+folder if error==OK else tr("导出失败：")+error_string(error))

func _animation_dialog(domain: String) -> void:
	var d: Dictionary = pages[domain]
	if d.animation_exporting:
		d.status.text="动画正在导出，请等待完成。"
		return
	_dialog("选择循环动画导出位置",FileDialog.FILE_MODE_OPEN_DIR,func(path: String) -> void:
		var p: Dictionary = d.parameters.duplicate(true)
		var folder: String = path.path_join(domain+"_animation_"+str(p.seed)+"_"+str(Time.get_ticks_msec()))
		d.animation_exporting=true
		d.cancel_export=false
		d.cancel_button.visible=true
		var exporter := Pipeline.new()
		add_child(exporter)
		var error: Error = await exporter.export_animation(domain,p,folder,func(frame: int,total: int) -> void:
			d.status.text=tr("动画导出 %d / %d 帧")%[frame,total],func() -> bool: return d.cancel_export)
		exporter.queue_free()
		d.animation_exporting=false
		d.cancel_button.visible=false
		d.status.text=tr("动画已导出：")+folder if error==OK else (tr("已停止，部分文件保留在：")+folder if error==ERR_SKIP else tr("动画导出失败：")+error_string(error)))

func _preset_dialog(domain: String, loading: bool, palette_only: bool) -> void:
	_dialog("载入配置" if loading else "保存配置",FileDialog.FILE_MODE_OPEN_FILE if loading else FileDialog.FILE_MODE_SAVE_FILE,func(path: String) -> void:
		if loading:
			var error: String = load_preset(domain,path,palette_only)
			pages[domain].status.text = "配置已载入，正在更新预览。" if error.is_empty() else error
		else:
			var parameters: Dictionary = pages[domain].parameters.duplicate(true)
			if palette_only:
				for key in parameters.keys():
					if not parameters[key] is String: parameters.erase(key)
			var data: Dictionary = {"format":"pixel-cosmos-palette" if palette_only else "pixel-cosmos-preset","version":2,"domain":domain,"parameters":parameters}
			var error: Error = Pipeline.write_json(path,data)
			pages[domain].status.text = tr("已保存：")+path if error==OK else error_string(error))

func load_preset(domain: String, path: String, palette_only: bool = false) -> String:
	return apply_preset_data(domain,JSON.parse_string(FileAccess.get_file_as_string(path)),palette_only)

func apply_preset_data(domain: String, data: Variant, palette_only: bool = false) -> String:
	if not data is Dictionary or data.get("version")!=2 or data.get("domain")!=domain: return "配置格式或页面类型不匹配。"
	var expected: String = "pixel-cosmos-palette" if palette_only else "pixel-cosmos-preset"
	if data.get("format")!=expected or not data.get("parameters") is Dictionary: return "不是有效的配置文件。"
	var incoming: Dictionary = data.parameters
	if palette_only:
		var merged: Dictionary = pages[domain].parameters.duplicate(true)
		for key in incoming:
			if not merged.has(key) or not merged[key] is String: return "色板包含不支持的项目。"
			merged[key] = incoming[key]
		incoming = merged
	var checked: Dictionary = Schema.validate(domain,incoming)
	if checked.has("error"): return checked.error
	pages[domain].parameters = checked.parameters
	_sync_widgets(domain)
	_dirty(domain)
	return ""

func _settings_page(parent: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",7)
	scroll.add_child(list)
	return list

func _motion_controls(domain: String, parent: Control) -> void:
	var d: Dictionary = pages[domain]
	var testing: bool = "--smoke" in OS.get_cmdline_user_args() or "--ui-smoke" in OS.get_cmdline_user_args() or "--motion-smoke" in OS.get_cmdline_user_args()
	d.merge({"noise_time":0.0,"motion_playing":not testing,"motion_materials":[],"motion_preview":not testing,"animation_exporting":false})
	var row := HBoxContainer.new()
	parent.add_child(row)
	var play := CheckButton.new()
	play.text="播放噪声"
	play.button_pressed=d.motion_playing
	play.toggled.connect(func(value: bool) -> void:
		d.motion_playing=value
		d.motion_preview=true
		_apply_motion(domain))
	row.add_child(play)
	d.play_button=play
	_button(row,"回到开头",func() -> void: _set_motion_time(domain,0.0))
	var timeline := HSlider.new()
	timeline.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	timeline.max_value=d.parameters.noise_duration
	timeline.step=.01
	row.add_child(timeline)
	d.timeline=timeline
	timeline.value_changed.connect(func(value: float) -> void:
		d.motion_playing=false
		play.set_pressed_no_signal(false)
		d.motion_preview=true
		_apply_motion(domain)
		_set_motion_time(domain,value))
	var label := Label.new()
	label.custom_minimum_size.x=95
	row.add_child(label)
	d.time_label=label
	_set_motion_time(domain,0.0)

func _set_motion_time(domain: String, seconds: float) -> void:
	var d: Dictionary = pages[domain]
	d.noise_time=seconds
	d.timeline.max_value=d.parameters.noise_duration
	d.timeline.set_value_no_signal(seconds)
	d.time_label.text=tr("%.1f / %.0f 秒")%[seconds,d.parameters.noise_duration]
	for mat in d.motion_materials:
		mat.set_shader_parameter("noise_time",fposmod(seconds,d.parameters.noise_duration))

func _apply_motion(domain: String) -> void:
	var d: Dictionary = pages[domain]
	if not d.has("motion_materials") or d.result.is_empty(): return
	d.motion_materials=[]
	if not d.motion_preview or not d.result.parameters.noise_enabled:
		if domain=="sky": d.environment.environment.sky=d.result.sky
		return
	if domain=="planet":
		for child in d.result.node.get_children():
			if child.name=="Rings": continue
			var mat: ShaderMaterial = Motion.planet_material(d.result.parameters,child.name=="CloudShell",d.style,d.levels,d.style_dither)
			for index in child.mesh.get_surface_count(): child.set_surface_override_material(index,mat)
			d.motion_materials.append(mat)
	else:
		var mat: ShaderMaterial = Motion.sky_material(d.result.parameters)
		var sky := Sky.new()
		sky.sky_material=mat
		d.environment.environment.sky=sky
		d.motion_materials.append(mat)
	_set_motion_time(domain,d.noise_time)
	if domain=="sky": update_background()

func _label(parent: Control, title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color",Color("b3c4d8"))
	label.add_theme_font_size_override("font_size",13)
	parent.add_child(label)

func _new_seed(domain: String) -> void:
	pages[domain].parameters.seed = randi_range(1,999999)
	_sync_widgets(domain)
	_dirty(domain)

func _reset_colors(domain: String) -> void:
	var defaults: Dictionary = Schema.type_defaults(pages[domain].parameters.type) if domain=="planet" else Schema.defaults(domain)
	for field in Schema.fields(domain):
		if field[2] is String: pages[domain].parameters[field[0]]=defaults[field[0]]
	_sync_widgets(domain)
	_dirty(domain)

func _space_schemes(parent: Control) -> void:
	_label(parent,"原版配色方案")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 165
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var schemes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/space_palettes.json"))
	for scheme in schemes:
		var button := Button.new()
		button.custom_minimum_size.y = 28
		button.tooltip_text = scheme.name
		list.add_child(button)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left=6
		row.offset_right=-6
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var label := Label.new()
		label.text=scheme.name
		label.add_theme_font_size_override("font_size",12)
		label.custom_minimum_size.x=145
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		for hex in scheme.colors:
			var swatch := ColorRect.new()
			swatch.color=Color(hex)
			swatch.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE
			row.add_child(swatch)
		button.pressed.connect(func() -> void:
			pages.sky.parameters.background_color=scheme.colors[0]
			for i in 8: pages.sky.parameters["palette"+str(i)]=scheme.colors[i+1]
			_sync_widgets("sky")
			_dirty("sky"))

func _refresh_tab_titles() -> void:
	for i in tabs.get_tab_count():
		tabs.set_tab_title(i,tr("星球生成" if i==0 else "星空生成"))
	for domain in pages:
		if not pages[domain].has("settings_tabs"): continue
		var titles: Array=["常用","动态","高级","配置"]
		for i in 4: pages[domain].settings_tabs.set_tab_title(i,tr(titles[i]))
