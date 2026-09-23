extends RefCounted

const UNBOUNDED = ["noise_scale", "cloud_scale", "nebula_scale", "dust_scale"]

const TYPES: Array[String] = ["湿润星球","干旱星球","群岛星球","无大气星球","气态星球一","气态星球二","冰冻星球","熔岩星球"]

# key, label, default, minimum, maximum, step, group. Palette slots are sRGB hex.
static func fields(domain: String, planet_type: int = 2) -> Array:
	var common: Array = [
		["seed","种子",7421,1,999999,1,"基础"],
		["face_size","每面贴图尺寸",128 if domain=="planet" else 512,32,1024,32,"基础"],
		["pixel_art","像素风格",true,0,0,0,"像素与细节"],
		["pixels","球面像素密度",100 if domain=="planet" else 200,12 if domain=="planet" else 100,5000 if domain=="planet" else 3000,1,"像素与细节"],
		["dither","点阵过渡",true,0,0,0,"像素与细节"],
		["dither_size","点阵大小",1,1,8,1,"像素与细节"],
		["rotation","表面图案旋转（弧度）",.2,0,6.28,.01,"基础"]]
	if domain=="planet":
		common.append_array([
			["type","星球类型",2,0,7,1,"基础"],
			["voxel","体素形态",false,0,0,0,"基础"],
			["voxel_size","体素直径",32,12,64,2,"基础"],
			["radius","星球半径（米）",1.0,.25,10,.05,"基础"],
			["surface_enabled","显示表面",true,0,0,0,"表面"],
			["surface_seed","地貌独立种子偏移",0,0,9999,1,"表面"],
			["noise_scale","地貌大小（数值越大越细）",2.146,.2,20,.05,"表面"],
			["octaves","噪声细节层数",6,0,20,1,"表面"],
			["land_cutoff","陆地覆盖阈值",.633,0,1,.001,"表面"],
			["land_enabled","显示陆地",true,0,0,0,"表面"],
			["water_enabled","显示水面",true,0,0,0,"表面"],
			["rivers_enabled","显示河流",true,0,0,0,"地貌特征"],
			["lakes_enabled","显示湖泊",true,0,0,0,"地貌特征"],
			["craters_enabled","显示陨坑",true,0,0,0,"地貌特征"],
			["river_cutoff","河流宽度",.04,0,.2,.005,"地貌特征"],
			["lake_cutoff","湖泊阈值",.55,0,1,.001,"地貌特征"],
			["crater_scale","陨坑密度",9,2,30,1,"地貌特征"],
			["crater_depth","陨坑色彩深度",.6,0,1,.05,"地貌特征"],
			["ice_coverage","极地冰盖范围",.35,0,1,.01,"地貌特征"],
			["lava_cutoff","熔岩覆盖阈值",.55,.1,.9,.01,"地貌特征"],
			["bands","气态条带数量",16,2,48,1,"地貌特征"],
			["swirl","气态条带扰动",2.2,0,8,.1,"地貌特征"],
			["clouds_enabled","显示云层",true,0,0,0,"云层"],
			["cloud_seed","云层独立种子偏移",13,0,9999,1,"云层"],
			["cloud_cover","云阈值（越大越少）",.415,0,1,.001,"云层"],
			["cloud_scale","云层细节大小",3.8725,.2,20,.05,"云层"],
			["cloud_octaves","云层细节层数",2,0,20,1,"云层"],
			["cloud_stretch","云带拉伸",2.0,1,3,.001,"云层"],
			["cloud_curve","云层弯曲",1.3,1,2,.001,"云层"],
			["cloud_height","云层高度（半径比例）",.025,.005,.2,.005,"云层"],
			["cloud_speed","云层速度 °/秒",2.0,-30,30,.1,"运动"],
			["rotation_speed","自转速度 °/秒",4.0,-30,30,.1,"运动"],
			["phase","云层初始相位 °",0,0,360,1,"运动"],
			["rings_enabled","显示星环",false,0,0,0,"星环"],
			["ring_radius","星环内半径（半径比例）",1.3,1.1,3,.05,"星环"],
			["ring_width","星环宽度（半径比例）",.6,.1,2,.05,"星环"],
			["ring_tilt","星环倾角 °",20,-80,80,1,"星环"],
			["ring_bands","星环条纹数量",32,4,100,1,"星环"],
			["roughness","表面粗糙度",1.0,.05,1,.05,"材质"],
			["metallic","金属度",0.0,0,1,.05,"材质"],
			["water0","水色 A","92e8c0",0,0,0,"色板"],
			["water1","水色 B","4fa4b8",0,0,0,"色板"],
			["water2","水色 C","2c354d",0,0,0,"色板"],
			["land0","陆地色 A","c8d45d",0,0,0,"色板"],
			["land1","陆地色 B","63ab3f",0,0,0,"色板"],
			["land2","陆地色 C","2f5753",0,0,0,"色板"],
			["land3","陆地色 D","283540",0,0,0,"色板"],
			["cloud0","云色 A","dfe0e8",0,0,0,"色板"],
			["cloud1","云色 B","a3a7c2",0,0,0,"色板"],
			["cloud2","云色 C","686f99",0,0,0,"色板"],
			["cloud3","云色 D","404973",0,0,0,"色板"],
			["ring_color","星环颜色","cfb581",0,0,0,"色板"]])
	else:
		common.append_array([
			["background_color","背景色","13140d",0,0,0,"色板"],
			["transparent","透明背景导出",false,0,0,0,"基础"],
			["reduce_background","减弱背景",false,0,0,0,"基础"],
			["nebula_enabled","显示星云",true,0,0,0,"星云"],
			["nebula_seed","星云独立种子偏移",0,0,9999,1,"星云"],
			["nebula_scale","星云大小（越大越细）",5.0,.5,30,.1,"星云"],
			["nebula_octaves","星云细节层数",3,0,20,1,"星云"],
			["density","星云密度",.5,0,1,.01,"星云"],
			["nebula_brightness","星云亮度",1.0,.1,2,.05,"星云"],
			["dust_enabled","显示星尘",true,0,0,0,"星尘"],
			["dust_seed","星尘独立种子偏移",2,0,9999,1,"星尘"],
			["dust_scale","星尘大小（越大越细）",10.0,1,50,.5,"星尘"],
			["dust_octaves","星尘细节层数",8,0,20,1,"星尘"],
			["dust_density","星尘密度",1.8,0,4,.05,"星尘"],
			["dust_brightness","星尘亮度",1.0,.1,2,.05,"星尘"],
			["stars_enabled","显示星点",true,0,0,0,"星点"],
			["stars_seed","星点独立种子偏移",73,0,9999,1,"星点"],
			["star_density","星点密度",.004,0,.04,.001,"星点"],
			["star_size","星点大小",1.0,.3,3,.1,"星点"],
			["star_brightness","星点亮度",1.0,.1,2,.05,"星点"],
			["bright_enabled","显示亮星",true,0,0,0,"亮星"],
			["bright_count","亮星数量",100,0,200,1,"亮星"],
			["bright_size","亮星大小",.07,.01,.2,.005,"亮星"],
			["decor_enabled","显示远景行星",false,0,0,0,"远景行星"],
			["decor_count","远景行星数量",8,0,32,1,"远景行星"],
			["decor_size","远景行星大小",.04,.01,.12,.005,"远景行星"]])
		var colors: Array = ["202215","3a2802","963c3c","ca5a2e","ff7831","f39949","ebc275","dfd785"]
		for i in 8: common.append(["palette"+str(i),"色板 "+str(i+1),colors[i],0,0,0,"色板"])
	common.append_array(preload("res://noise_motion.gd").fields(domain))
	if domain=="planet":
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_controls.json"))
		var authored: Dictionary = source.planet_types[planet_type].defaults
		for field in common:
			if authored.has(field[0]):
				field[2] = int(authored[field[0]]) if field[0].ends_with("octaves") else float(authored[field[0]])
	return common

static func defaults(domain: String) -> Dictionary:
	var result: Dictionary = {}
	for field in fields(domain): result[field[0]] = field[2]
	return result

static func type_defaults(index: int) -> Dictionary:
	var p: Dictionary = defaults("planet")
	for field in fields("planet",index): p[field[0]]=field[2]
	p.type = index
	p.clouds_enabled = index in [0,2,6]
	p.rings_enabled = index==5
	var palettes: Array = [
		["63ab3f","3b7d4f","2f5753","283540"],
		["ff8933","e64539","ad2f45","52333f"],
		["c8d45d","63ab3f","2f5753","283540"],
		["a3a7c2","4c6885","3a3f5e","3a3f5e"],
		["f0b541","cf752b","ab512f","7d3833"],
		["eec397","d9a066","8f5639","663931"],
		["faffff","c7d4e1","9290b8","404973"],
		["ff8933","e64539","52333f","3d2936"]]
	for i in 4: p["land"+str(i)] = palettes[index][i]
	return p

static func validate(domain: String, source: Dictionary) -> Dictionary:
	# Explicitly reject wrong values; do not silently turn a malformed file into a preset.
	if domain=="planet" and (not source.get("type") is float and not source.get("type") is int): return {"error":"星球类型格式或范围错误"}
	if domain=="planet" and (source.type<0 or source.type>7 or source.type!=floor(source.type)): return {"error":"星球类型格式或范围错误"}
	var result: Dictionary = {}
	for f in fields(domain,int(source.get("type",2)) if domain=="planet" else 2):
		if not source.has(f[0]):
			if f[6]=="动态噪声":
				result[f[0]]=f[2]
				continue
			return {"error":"缺少参数："+f[0]}
		var v: Variant = source[f[0]]
		if f[2] is bool:
			if not v is bool: return {"error":"开关格式错误："+f[0]}
		elif f[2] is String:
			if not v is String or not Color.html_is_valid(v): return {"error":"颜色格式错误："+f[0]}
		else:
			if not (v is float or v is int): return {"error":"数值格式错误："+f[0]}
			if not is_finite(float(v)) or (not f[0] in UNBOUNDED and (v<f[3] or v>f[4])): return {"error":"数值超出范围："+f[0]}
			if f[2] is int and v!=floor(v): return {"error":"需要整数："+f[0]}
			v = int(v) if f[2] is int else float(v)
		result[f[0]] = v
	return {"parameters":result}
